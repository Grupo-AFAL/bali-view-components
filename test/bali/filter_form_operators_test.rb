# frozen_string_literal: true

require "test_helper"

# #1566. `filter_attribute operators:` narrows the advanced panel's operators for one attribute,
# and `default_operator:` picks the one a new condition opens on.
class BaliFilterFormOperatorsTest < ComponentTestCase
  include RansackTestHelpers

  class CodesFilterForm < Bali::FilterForm
    filter_attribute :name, type: :text, operators: %i[eq start]
    filter_attribute :genre, type: :text, default_operator: :eq
    filter_attribute :release_date, type: :date, operators: %i[between]
    filter_attribute :website_url, type: :text
  end

  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", genre: "Drama", release_date: "2026-01-10", studio: studio)
    @anabel = Movie.create!(name: "Anabel", genre: "Action", release_date: "2026-03-10", studio: studio)
  end

  test "the panel offers the attribute what it declares, in that order" do
    attributes = CodesFilterForm.new(Movie.all).available_attributes.index_by { |attribute| attribute[:key] }

    assert_equal [ "eq", text("start") ], Bali::Filters::Operators.for_attribute(attributes[:name]).pluck(:value)
    assert_equal "eq", Bali::Filters::Operators.default_for(attributes[:name])
    assert_equal "eq", Bali::Filters::Operators.default_for(attributes[:genre])
    assert_equal Bali::Filters::Operators.for_type(:text).pluck(:value),
                 Bali::Filters::Operators.for_attribute(attributes[:genre]).pluck(:value)
    assert_equal({ key: :website_url, type: :text, label: "Website url", options: [] }, attributes[:website_url])
    assert_nil Bali::Filters::Operators.default_for(attributes[:website_url])
  end

  test "an operator the attribute does not offer is no filter, from a URL or a saved view" do
    from_url = form("0" => { "name_cont" => "Ana", "genre_cont" => "Dra" })
    from_view = CodesFilterForm.new(
      Movie.all, ActionController::Parameters.new(saved_view: "1"),
      saved_views_store: Store.new(View.new(1, "Ana's", { "groupings" => { "0" => { "name_cont" => "Ana" } } }))
    )

    assert_equal [ [ "genre", text("cont"), "Dra" ] ], conditions(from_url)
    assert_equal [ @ana ], from_url.result.to_a
    assert_empty from_view.filter_groups
    assert_equal 2, from_view.result.count
  end

  test "an operator it offers filters" do
    applied = form("0" => { "name_eq" => "Ana" })

    assert_equal [ [ "name", "eq", "Ana" ] ], conditions(applied)
    assert_equal [ @ana ], applied.result.to_a
  end

  test "a between it offers travels as its pair" do
    applied = form("0" => { "release_date_gteq" => "2026-01-01", "release_date_lteq" => "2026-01-31" })

    assert_equal [ [ "release_date", "between", { start: "2026-01-01", end: "2026-01-31" } ] ], conditions(applied)
    assert_equal [ @ana ], applied.result.to_a
  end

  # "between" lets its `gteq` and `lteq` through, each alone too (`Operators.predicates_for`), and
  # they fold back into a "between" only inside an AND group.
  test "an OR group draws the bounds of a between-only date with their own operators" do
    opened = form("0" => { "m" => "or", "release_date_gteq" => "2026-03-01", "release_date_lteq" => "2026-01-31" })

    assert_equal [ @ana, @anabel ], opened.result.order(:release_date).to_a
    assert_equal [ [ "gteq", false, [ "q[g][0][release_date_gteq]" ] ], [ "lteq", false, [ "q[g][0][release_date_lteq]" ] ] ],
                 drawn(opened)
  end

  test "a view saved with one end of a between-only date filters and draws that end" do
    from_view = CodesFilterForm.new(
      Movie.all, ActionController::Parameters.new(saved_view: "1"),
      saved_views_store: Store.new(View.new(1, "Since March", { "groupings" => { "0" => { "release_date_gteq" => "2026-03-01" } } }))
    )

    assert_equal [ @anabel ], from_view.result.to_a
    assert_equal [ [ "gteq", false, [ "q[g][0][release_date_gteq]" ] ] ], drawn(from_view)
  end

  test "a date that does not offer between paints its bounds apart" do
    bounded = Class.new(Bali::FilterForm) { filter_attribute :release_date, type: :date, operators: %i[gteq lteq] }
    applied = bounded.new(Movie.all, ActionController::Parameters.new(
                                       q: { g: { "0" => { "release_date_gteq" => "2026-01-01", "release_date_lteq" => "2026-01-31" } } }
                                     ))

    assert_equal [ [ "release_date", "gteq", "2026-01-01" ], [ "release_date", "lteq", "2026-01-31" ] ], conditions(applied)
  end

  test "an advanced default is applied with the default operator" do
    defaulted = Class.new(Bali::FilterForm) { filter_attribute :name, type: :text, operators: %i[start], default: "Ana" }

    assert_equal({ "g" => { "0" => { "name_#{text('start')}" => "Ana", "m" => "and" } } }, defaulted.default_filter_params)
  end

  test "an operator the type does not offer raises when the form is declared" do
    [
      [ { type: :text, operators: %i[gt] }, /type :text offers no operator gt/ ],
      [ { type: :text, operators: [] }, /offers no operator \(empty list\)/ ],
      [ { type: :text, operators: %i[eq], default_operator: :cont }, /default_operator: :cont is not among its operators \(eq\)/ ],
      [ { type: :number, default_operator: :cont }, /default_operator: :cont is not among its operators/ ],
      [ { type: :select, operators: %i[eq], simple: true, advanced: false }, /apply to the advanced panel/ ],
      [ { type: :date, default_operator: :between, default: "2026-01-01" }, /default: is applied with :between/ ]
    ].each do |options, message|
      error = assert_raises(ArgumentError, options.inspect) { Class.new(Bali::FilterForm) { filter_attribute :name, **options } }
      assert_match message, error.message
    end
  end

  private

  def form(groups)
    CodesFilterForm.new(Movie.all, ActionController::Parameters.new(q: { g: groups }))
  end

  # Each row the panel draws: the operator its select shows (the first one when no option is
  # selected, as a browser does), whether the select is disabled, and the names its value submits.
  def drawn(form)
    render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: form.available_attributes,
                                               filter_form: form, popover: false))
    page.all("[data-filters-target='groupsContainer'] [data-controller='condition']", visible: :all).map do |row|
      select = row.find("[data-condition-target='operator']", visible: :all)
      [ select.value, select.disabled?, row.all("[data-condition-target='valueContainer'] [name]", visible: :all).pluck(:name) ]
    end
  end
end
