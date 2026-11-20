# frozen_string_literal: true

require "test_helper"

# #1613. `filter_attribute nullable: true` (or `operators:` naming them) offers "is empty" and
# "is not empty" in the advanced panel. They take no value: the condition travels as
# `q[g][N][attribute_null]=1` (`_blank` on text, which also counts the empty string).
class BaliFilterFormEmptyOperatorsTest < ComponentTestCase
  include RansackTestHelpers

  class MoviesFilterForm < Bali::FilterForm
    filter_attribute :genre, type: :select, nullable: true, options: [ %w[Drama Drama], %w[Action Action] ]
    filter_attribute :synopsis, type: :text, nullable: true
    filter_attribute :budget, type: :number, nullable: true
    filter_attribute :release_date, type: :date, nullable: true
    filter_attribute :indie, type: :boolean, nullable: true
    filter_attribute :budget_band, type: :select, nullable: true, options: [ %w[indie indie] ]
    filter_attribute :name, type: :text
    filter_attribute :time_zone, type: :select, options: [ %w[UTC UTC] ], operators: %i[eq null]
  end

  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @blank_genre = Movie.create!(name: "No genre", genre: nil, synopsis: "", budget: nil, release_date: nil, studio: studio)
    @filled = Movie.create!(name: "Complete", genre: "Drama", synopsis: "A story", budget: 100,
                            release_date: "2026-01-10", indie: true, studio: studio)
  end

  test "an attribute offers the empty operators only when it asks, after its own" do
    offered = ->(attribute) { Bali::Filters::Operators.for_attribute(attribute).pluck(:value) }

    assert_equal %w[eq not_eq in not_in], offered.call({ key: :genre, type: :select })
    assert_equal %w[eq not_eq in not_in null not_null], offered.call({ key: :genre, type: :select, nullable: true })
    assert_equal %w[eq not_eq gt lt gteq lteq null not_null], offered.call({ key: :budget, type: :number, nullable: true })
    assert_equal %w[eq between gt lt gteq lteq null not_null], offered.call({ key: :at, type: :date, nullable: true })
    assert_equal %w[eq null not_null], offered.call({ key: :indie, type: :boolean, nullable: true })
    assert_equal [ text("cont"), "eq", text("start"), text("end"), text("not_cont"), "not_eq", "blank", "present" ],
                 offered.call({ key: :synopsis, type: :text, nullable: true })
  end

  test "operators may name them, and nullable adds them to what operators lists" do
    offered = ->(attribute) { Bali::Filters::Operators.for_attribute(attribute).pluck(:value) }

    assert_equal %w[eq null], offered.call({ key: :genre, type: :select, operators: %i[eq null] })
    assert_equal %w[eq present], offered.call({ key: :synopsis, type: :text, operators: %i[eq present] })
    assert_equal %w[eq null not_null], offered.call({ key: :genre, type: :select, operators: %i[eq null], nullable: true })
  end

  test "an empty operator the type does not offer raises" do
    { { type: :text, operators: %i[null] } => "null", { type: :number, operators: %i[blank] } => "blank" }.each do |attribute, unknown|
      error = assert_raises(ArgumentError) { Bali::Filters::Operators.for_attribute({ key: :code, **attribute }) }
      assert_match "code: type :#{attribute[:type]} offers no operator #{unknown} (valid:", error.message
    end
  end

  test "the four are marked as taking no value, and nothing else is" do
    marked = Bali::Filters::Operators.for_type(:text, nullable: true).select { |operator| operator[:valueless] }
    assert_equal %w[blank present], marked.pluck(:value)
    assert_equal [ "is empty", "is not empty" ], I18n.with_locale(:en) { Bali::Filters::Operators.for_type(:number, nullable: true).last(2).pluck(:label) }
    assert_equal [ "está vacío", "no está vacío" ], I18n.with_locale(:es) { Bali::Filters::Operators.for_type(:number, nullable: true).last(2).pluck(:label) }
    assert_equal %w[null not_null], Bali::Filters::Operators.for_type(:date, nullable: true).last(2).pluck(:value)
    assert(%w[null not_null blank present].all? { |operator| Bali::Filters::Operators.valueless?(operator) })
    refute(%w[eq in between cont].any? { |operator| Bali::Filters::Operators.valueless?(operator) })
    assert_empty Bali::Filters::Operators.for_type(:select).select { |operator| operator[:valueless] }
  end

  test "an empty condition filters, and the panel reads it back" do
    {
      "genre_null" => [ [ "genre", "null", "1" ], [ @blank_genre ] ],
      "genre_not_null" => [ [ "genre", "not_null", "1" ], [ @filled ] ],
      "synopsis_blank" => [ [ "synopsis", "blank", "1" ], [ @blank_genre ] ],
      "synopsis_present" => [ [ "synopsis", "present", "1" ], [ @filled ] ],
      "budget_null" => [ [ "budget", "null", "1" ], [ @blank_genre ] ],
      "release_date_not_null" => [ [ "release_date", "not_null", "1" ], [ @filled ] ],
      "time_zone_null" => [ [ "time_zone", "null", "1" ], [ @blank_genre, @filled ] ]
    }.each do |key, (condition, expected)|
      applied = form("0" => { key => "1" })

      assert_equal [ condition ], conditions(applied), key
      assert_equal expected.sort_by(&:id), applied.result.order(:id).to_a, key
    end
  end

  test "text counts the empty string as empty and a select only NULL" do
    assert_equal [ @blank_genre ], form("0" => { "synopsis_blank" => "true" }).result.to_a
    assert_empty form("0" => { "genre_not_null" => "1", "synopsis_blank" => "1" }).result.where(name: "Complete")
  end

  # `budget_band` is a SQL CASE the dummy's Movie declares as a ransacker.
  test "over a ransacker it asks the expression" do
    applied = form("0" => { "budget_band_not_null" => "1" })

    assert_equal [ [ "budget_band", "not_null", "1" ] ], conditions(applied)
    assert_match(/END IS NOT NULL/, applied.result.to_sql)
    assert_equal 2, applied.result.count
    assert_empty form("0" => { "budget_band_null" => "1" }).result
  end

  test "an empty condition combines with the others of its group" do
    applied = form("0" => { "m" => "and", "genre_not_null" => "1", "name_eq" => "Complete" })

    assert_equal [ [ "genre", "not_null", "1" ], [ "name", "eq", "Complete" ] ], conditions(applied)
    assert_equal [ @filled ], applied.result.to_a
  end

  test "a flag that is not true is no filter, because the panel would paint the opposite" do
    %w[0 false].each do |flag|
      applied = form("0" => { "genre_null" => flag })

      assert_empty applied.filter_groups, flag
      assert_equal 2, applied.result.count, flag
    end
  end

  test "an attribute that does not offer them takes no empty condition, from a URL or a saved view" do
    from_url = form("0" => { "name_null" => "1", "genre_null" => "1" })

    assert_equal [ [ "genre", "null", "1" ] ], conditions(from_url)
    assert_equal [ @blank_genre ], from_url.result.to_a

    from_view = from_saved_view("0" => { "name_blank" => "1" })

    assert_empty from_view.filter_groups
    assert_equal 2, from_view.result.count
  end

  test "a saved view carrying an empty condition filters and counts it" do
    from_view = from_saved_view("0" => { "genre_null" => "1" })

    assert_equal [ [ "genre", "null", "1" ] ], conditions(from_view)
    assert_equal [ @blank_genre ], from_view.result.to_a
    assert_equal 1, from_view.active_filters_count
  end

  test "the applied state travels and counts like any condition" do
    applied = form("0" => { "genre_null" => "1", "synopsis_present" => "1" })

    assert_equal [ [ "q[g][0][m]", "and" ], [ "q[g][0][genre_null]", "1" ], [ "q[g][0][synopsis_present]", "1" ] ],
                 Bali::Filters::ActiveFilterParams.for_filter_form(applied)
    assert_equal 2, applied.active_filters_count
    assert_equal [ nil, nil ], applied.active_filter_details.pluck(:value_label)
  end

  test "a row draws no value widget, and submits the one flag" do
    rows = drawn(form("0" => { "genre_null" => "1", "budget_not_null" => "1", "synopsis_blank" => "1" }))

    assert_equal [ [ "null", [ "q[g][0][genre_null]" ] ], [ "not_null", [ "q[g][0][budget_not_null]" ] ],
                  [ "blank", [ "q[g][0][synopsis_blank]" ] ] ], rows.map { |operator, names, widgets| [ operator, names ] }
    assert(rows.all? { |_, _, widgets| widgets == [ [ "hidden", "1" ] ] })
  end

  test "the operator select carries the mark the controller reads" do
    render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: MoviesFilterForm.new(Movie.all).available_attributes,
                                               filter_form: form("0" => { "genre_null" => "1" }), popover: false))
    options = page.all("[data-condition-target='operator'] option", visible: :all).to_h { |option| [ option.value, option["data-valueless"] ] }

    assert_equal({ "eq" => "false", "not_eq" => "false", "in" => "false", "not_in" => "false", "null" => "true", "not_null" => "true" }, options)
  end

  test "the pill names the attribute and the operator and has no value" do
    render_inline(Bali::Filters::AppliedTags::Component.new(
                    filter_groups: form("0" => { "genre_null" => "1" }).filter_groups,
                    available_attributes: MoviesFilterForm.new(Movie.all).available_attributes, url: "/movies"
                  ))

    tag = page.find("[data-applied-tags-target='tag']")
    assert_equal "Genre #{I18n.t('bali_view.filters.operators.is_empty')}", tag.text.squish
    assert_equal "#{I18n.t('bali_view.filters.remove_filter')}: Genre #{I18n.t('bali_view.filters.operators.is_empty')}",
                 tag.find("button")["aria-label"]
  end

  test "an attribute hash built in a view takes nullable too" do
    render_inline(Bali::Filters::Component.new(url: "/movies", popover: false,
                                               available_attributes: [ { key: :owner, type: :select, nullable: true, options: [ %w[Ana ana] ] } ]))
    option = page.first("[data-condition-target='attribute'] option[value='owner']", visible: :all)

    assert_equal %w[eq not_eq in not_in null not_null], JSON.parse(option["data-operators"]).pluck("value")
    assert_equal [ true, true ], JSON.parse(option["data-operators"]).last(2).pluck("valueless")
  end

  test "the declaration is checked when the form is declared" do
    [
      [ { type: :select, nullable: true, simple: true, advanced: false }, /apply to the advanced panel/ ],
      [ { type: :text, nullable: true, default_operator: :blank, default: "x" }, /default_operator: :blank takes no value/ ]
    ].each do |options, message|
      error = assert_raises(ArgumentError, options.inspect) { Class.new(Bali::FilterForm) { filter_attribute :name, **options } }
      assert_match message, error.message
    end
  end

  test "a condition can open on an empty operator" do
    opening = Class.new(Bali::FilterForm) { filter_attribute :genre, type: :select, nullable: true, default_operator: :null }

    assert_equal "null", Bali::Filters::Operators.default_for(opening.new(Movie.all).available_attributes.first)
  end

  test "the attribute hash carries nullable only when it is on" do
    attributes = MoviesFilterForm.new(Movie.all).available_attributes.index_by { |attribute| attribute[:key] }

    assert attributes[:genre][:nullable]
    refute attributes[:name].key?(:nullable)
  end

  private

  def form(groups)
    MoviesFilterForm.new(Movie.all, ActionController::Parameters.new(q: { g: groups }))
  end

  def from_saved_view(groupings)
    store = Store.new(View.new(1, "Saved", { "groupings" => groupings }))
    MoviesFilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"), saved_views_store: store)
  end

  # Each row the panel draws: the operator its select shows, the names its value submits, and
  # the type and value of each of those inputs.
  def drawn(form)
    render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: form.available_attributes,
                                               filter_form: form, popover: false))
    page.all("[data-filters-target='groupsContainer'] [data-controller='condition']", visible: :all).map do |row|
      select = row.find("[data-condition-target='operator']", visible: :all)
      inputs = row.all("[data-condition-target='valueContainer'] [name]", visible: :all)
      [ select.value, inputs.pluck(:name), inputs.map { |input| [ input[:type], input[:value] ] } ]
    end
  end
end
