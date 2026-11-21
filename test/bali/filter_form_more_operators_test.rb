# frozen_string_literal: true

require "test_helper"

# v3.29.0: the operators the advanced panel lacked next to Ransack's. "Does not start with" and
# "does not end with" on text, "between" on numbers, and "not on" on dates.
class BaliFilterFormMoreOperatorsTest < ComponentTestCase
  include RansackTestHelpers

  class MoviesFilterForm < Bali::FilterForm
    filter_attribute :name, type: :text
    filter_attribute :rating, type: :number
    filter_attribute :release_date, type: :date
    filter_attribute :created_at, type: :date
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", rating: 2, release_date: "2026-01-10", created_at: "2026-08-27 21:22:37", studio: studio)
    @anabel = Movie.create!(name: "Anabel", rating: 5, release_date: "2026-03-10", created_at: "2026-08-28 10:00:00", studio: studio)
    @bruno = Movie.create!(name: "Bruno", rating: 8, release_date: "2026-05-10", created_at: "2026-08-26 23:59:59", studio: studio)
  end

  test "the text operators end with the two negations, in the variant of the installed ransack" do
    assert_equal [ text("not_start"), text("not_end") ], Bali::Filters::Operators.for_type(:text).last(2).pluck(:value)
    assert_equal [ "does not start with", "does not end with" ],
                 I18n.with_locale(:en) { Bali::Filters::Operators.for_type(:text).last(2).pluck(:label) }
    assert_equal [ "no comienza con", "no termina con" ],
                 I18n.with_locale(:es) { Bali::Filters::Operators.for_type(:text).last(2).pluck(:label) }
  end

  test "does not start with and does not end with filter, and the panel reads them back" do
    starts = form("0" => { "name_#{text('not_start')}" => "An" })
    ends = form("0" => { "name_#{text('not_end')}" => "el" })

    assert_equal [ [ "name", text("not_start"), "An" ] ], conditions(starts)
    assert_equal [ @bruno ], starts.result.to_a
    assert_equal [ [ "name", text("not_end"), "el" ] ], conditions(ends)
    assert_equal [ @ana, @bruno ], ends.result.order(:id).to_a
  end

  # What was written before ransack 6 carries the plain name, which Bali reads as the variant of
  # the installed one.
  test "a link written with the plain negation is read in the variant of the installed ransack" do
    applied = form("0" => { "name_not_start" => "An" })

    assert_equal [ [ "name", text("not_start"), "An" ] ], conditions(applied)
    assert_equal [ @bruno ], applied.result.to_a
  end

  test "a number's two bounds fold into a between that filters and draws two inputs" do
    applied = form("0" => { "rating_gteq" => "2", "rating_lteq" => "5" })

    assert_equal [ [ "rating", "between", { start: "2", end: "5" } ] ], conditions(applied)
    assert_equal [ @ana, @anabel ], applied.result.order(:id).to_a
    assert_equal [ [ "between", [ "q[g][0][rating_gteq]", "q[g][0][rating_lteq]" ], [ "2", "5" ] ] ], drawn(applied)
    assert_equal [ [ "q[g][0][m]", "and" ], [ "q[g][0][rating_gteq]", "2" ], [ "q[g][0][rating_lteq]", "5" ] ],
                 Bali::Filters::ActiveFilterParams.for_filter_form(applied)
    assert_equal 1, applied.active_filters_count
  end

  test "a number's between is a range operator, so the pill reads both ends" do
    attributes = MoviesFilterForm.new(Movie.all).available_attributes
    groups = form("0" => { "rating_gteq" => "2", "rating_lteq" => "5" }).filter_groups
    render_inline(Bali::Filters::AppliedTags::Component.new(filter_groups: groups, available_attributes: attributes, url: "/movies"))

    assert_equal "Rating between 2 – 5", I18n.with_locale(:en) { page.find("[data-applied-tags-target='tag']").text.squish }
    assert(Bali::Filters::Operators.for_type(:number).last[:range])
  end

  test "not on a day leaves out every row of that day on a datetime column" do
    applied = form("0" => { "created_at_not_eq" => "2026-08-27" })

    assert_equal [ [ "created_at", "not_eq", "2026-08-27" ] ], conditions(applied)
    assert_equal [ @anabel, @bruno ], applied.result.order(:id).to_a
  end

  test "not on a minute leaves out the rows of that minute" do
    assert_equal [ @anabel, @bruno ], form("0" => { "created_at_not_eq" => "2026-08-27 21:22:00" }).result.order(:id).to_a
  end

  test "not on combines with the other conditions of an OR group" do
    applied = form("0" => { "m" => "or", "name_eq" => "Ana", "created_at_not_eq" => "2026-08-28" })

    assert_equal [ @ana, @bruno ], applied.result.order(:id).to_a
  end

  test "not on a day over a date column is the plain inequality" do
    applied = form("0" => { "release_date_not_eq" => "2026-01-10" })

    assert_equal [ @anabel, @bruno ], applied.result.order(:id).to_a
    assert_match(/!=/, applied.result.to_sql)
  end

  test "dates offer not on, labeled in both languages, after their other operators" do
    assert_equal "not_eq", Bali::Filters::Operators.for_type(:date).last[:value]
    assert_equal "not_eq", Bali::Filters::Operators.for_type(:datetime).last[:value]
    assert_equal [ "not on", "no es" ],
                 [ :en, :es ].map { |locale| I18n.with_locale(locale) { Bali::Filters::Operators.for_type(:date).last[:label] } }
  end

  test "the panel offers a number between and a date not on through the attribute" do
    attributes = MoviesFilterForm.new(Movie.all).available_attributes.index_by { |attribute| attribute[:key] }

    assert_includes Bali::Filters::Operators.for_attribute(attributes[:rating]).pluck(:value), "between"
    assert_includes Bali::Filters::Operators.for_attribute(attributes[:created_at]).pluck(:value), "not_eq"
    assert_equal %w[gteq lteq], Bali::Filters::Operators.predicates_for({ type: :number, operators: %i[between] })
  end

  private

  def form(groups)
    MoviesFilterForm.new(Movie.all, ActionController::Parameters.new(q: { g: groups }))
  end

  # Each row the panel draws: its operator, the names its value inputs submit and what they hold.
  def drawn(form)
    render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: form.available_attributes,
                                               filter_form: form, popover: false))
    page.all("[data-filters-target='groupsContainer'] [data-controller='condition']", visible: :all).map do |row|
      operator = row.find("[data-condition-target='operator']", visible: :all).value
      inputs = row.all("[data-condition-target='valueContainer'] [name]", visible: :all)
      [ operator, inputs.pluck(:name), inputs.pluck(:value) ]
    end
  end
end
