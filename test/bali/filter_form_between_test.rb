# frozen_string_literal: true

require "test_helper"

# #1528. The panel paints `filter_groups`, and its next submit applies what it painted. A `gteq`
# and an `lteq` on one attribute folded into one `between` whatever the group's combinator and
# whatever else the group asked of that attribute, so the panel showed another query than the
# one applied, and Apply then applied that one.
class BaliFilterFormBetweenTest < ComponentTestCase
  include RansackTestHelpers

  class RangesFilterForm < Bali::FilterForm
    filter_attribute :rating, type: :number
    filter_attribute :release_date, type: :date
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @low = Movie.create!(name: "Low", rating: 1, release_date: "2026-01-10", studio: studio)
    @mid = Movie.create!(name: "Mid", rating: 5, release_date: "2026-03-10", studio: studio)
    @high = Movie.create!(name: "High", rating: 9, release_date: "2026-05-10", studio: studio)
  end

  test "an OR of a lower and an upper bound stays two conditions" do
    applied = form("m" => "or", "release_date_gteq" => "2026-04-01", "release_date_lteq" => "2026-02-01")

    assert_equal [ [ "release_date", "gteq", "2026-04-01" ], [ "release_date", "lteq", "2026-02-01" ] ],
                 conditions(applied)
    assert_equal [ @low, @high ], applied.result.order(:rating).to_a
  end

  test "both bounds beside another operator of the attribute keep the three" do
    applied = form("release_date_gteq" => "2026-01-01", "release_date_lteq" => "2026-06-01",
                   "release_date_gt" => "2026-03-10")

    assert_equal [ [ "release_date", "gteq", "2026-01-01" ], [ "release_date", "lteq", "2026-06-01" ],
                   [ "release_date", "gt", "2026-03-10" ] ], conditions(applied)
    assert_equal [ @high ], applied.result.to_a
  end

  # A number offers no "between": folded, the row had no operator to show and named its input
  # `rating_between`, which the next submit could not apply.
  test "a number's bounds stay the conditions that arrived" do
    assert_equal [ [ "rating", "gteq", "2" ], [ "rating", "lteq", "8" ] ],
                 conditions(form("rating_gteq" => "2", "rating_lteq" => "8"))
    assert_equal [ [ "rating", "gteq", "1" ], [ "rating", "lteq", "9" ], [ "rating", "not_eq", "5" ] ],
                 conditions(form("rating_gteq" => "1", "rating_lteq" => "9", "rating_not_eq" => "5"))
  end

  test "a date's two bounds under AND are still its between" do
    assert_equal [ [ "release_date", "between", { start: "2026-02-01", end: "2026-04-01" } ] ],
                 conditions(form("release_date_gteq" => "2026-02-01", "release_date_lteq" => "2026-04-01"))
  end

  test "Apply on the panel as painted applies the query it was opened on" do
    [
      { "m" => "or", "rating_gteq" => "8", "rating_lteq" => "2" },
      { "m" => "and", "rating_gteq" => "1", "rating_lteq" => "9", "rating_not_eq" => "5" },
      { "m" => "and", "rating_gteq" => "2", "rating_lteq" => "8" },
      { "m" => "or", "release_date_gteq" => "2026-04-01", "release_date_lteq" => "2026-02-01" },
      { "m" => "and", "release_date_gteq" => "2026-01-01", "release_date_lteq" => "2026-06-01", "release_date_gt" => "2026-03-10" },
      { "m" => "and", "release_date_gteq" => "2026-02-01", "release_date_lteq" => "2026-04-01" }
    ].each do |group|
      opened = form(group)
      applied = RangesFilterForm.new(Movie.all, ActionController::Parameters.new(submitted_by_the_panel(opened)))

      assert_equal opened.filter_groups, applied.filter_groups, group.inspect
      assert_equal opened.result.order(:rating).to_a, applied.result.order(:rating).to_a, group.inspect
    end
  end

  private

  def form(group)
    RangesFilterForm.new(Movie.all, ActionController::Parameters.new(q: { g: { "0" => group } }))
  end

  # What filters_controller.js#buildUrl sends: the panel form's named fields with a value. The
  # rows a group's <template> holds are not in the form.
  def submitted_by_the_panel(form)
    render_inline(Bali::Filters::Component.new(url: "/movies", available_attributes: form.available_attributes,
                                               filter_form: form, popover: false))
    pairs = page.all(:xpath, "//*[@data-filters-target='groupsContainer']//*[@name][not(ancestor::template)]",
                     visible: :all).map { |field| [ field[:name], field.value ] }
    Rack::Utils.parse_nested_query(URI.encode_www_form(pairs.reject { |_, value| value.blank? }))
  end
end
