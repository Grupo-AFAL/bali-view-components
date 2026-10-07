# frozen_string_literal: true

require "test_helper"

# #1346. `q[g]` comes from a hand-written URL, a saved view or the filter cache, and the form
# handed Ransack whatever it could parse: some conditions were a 500 (and with the persistence
# or a saved view, a 500 on every visit), others filtered while the panel painted an empty row.
# Only what the panel can write gets through now; the rest is no filter.
class BaliFilterFormPanelConditionsTest < ActiveSupport::TestCase
  class PanelFilterForm < Bali::FilterForm
    search_fields :name

    filter_attribute :name, type: :text
    filter_attribute :genre, type: :select, options: [ %w[Drama Drama], %w[Action Action] ]
    filter_attribute :tenant_id, type: :select
    filter_attribute :studio_id, type: :select
    filter_attribute :release_date, type: :date
    filter_attribute :budget_band, type: :select
  end

  # identity's AccountsFilterForm: it reads the groups in its `initialize`, to round-trip them
  # through what "select all N" re-emits, and keeps what comes back.
  class ReemittingPanelFilterForm < PanelFilterForm
    def initialize(...)
      super
      @groupings = @groupings.transform_values { |group| group.except("name_cont") } if filter_groups.any?
    end
  end

  # A host that builds the panel per instance (afal-apps, identity) overrides this method.
  class RatedPanelFilterForm < PanelFilterForm
    def available_attributes
      super + [ { key: :rating, type: :number, label: "Rating" } ]
    end
  end

  NUMBER_PAST_ANY_COLUMN = "9" * 30

  def setup
    @studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", genre: "Drama", rating: 8, release_date: "2026-01-10", studio: @studio)
    @bob = Movie.create!(name: "Bob", genre: "Action", rating: 6, release_date: "2026-03-10", studio: @studio)
  end

  def form(groups, form_class: PanelFilterForm, **q)
    form_class.new(Movie.all, ActionController::Parameters.new(q: { g: groups, **q }))
  end

  def conditions(form)
    form.filter_groups.flat_map { |group| group[:conditions].map { |condition| condition.values_at(:attribute, :operator, :value) } }
  end

  test "each group keeps the conditions its attributes' operators can write" do
    applied = form({ "0" => { genre_cont: "Dra", genre_eq: "Drama", unknown_eq: "x", m: "or" },
                     "1" => { name_gteq: "A" } })

    assert_equal [ { combinator: "or", conditions: [ { attribute: "genre", operator: "eq", value: "Drama" } ] } ],
                 applied.filter_groups
    assert_equal [ @ana ], applied.result.to_a
  end

  test "a date's between travels as its pair" do
    applied = form({ "0" => { release_date_gteq: "2026-01-01", release_date_lteq: "2026-01-31" } })

    assert_equal [ [ "release_date", "between", { start: "2026-01-01", end: "2026-01-31" } ] ], conditions(applied)
    assert_equal [ @ana ], applied.result.to_a
  end

  test "a list only where the operator takes one" do
    applied = form({ "0" => { genre_eq: [ "Drama" ], genre_in: %w[Drama Action] },
                     "1" => { genre_not_in: "Action" } })

    assert_equal [ [ "genre", "in", %w[Drama Action] ], [ "genre", "not_in", "Action" ] ], conditions(applied)
  end

  test "a value with a control character is no filter" do
    applied = form({ "0" => { name_cont: "A\u0000na" }, "1" => { name_eq: "Ana\n" } })

    assert_empty applied.filter_groups
    assert_equal 2, applied.result.count
  end

  test "a list with an id past its column's type is no filter" do
    applied = form({ "0" => { tenant_id_in: [ NUMBER_PAST_ANY_COLUMN ] }, "1" => { studio_id_not_in: [ NUMBER_PAST_ANY_COLUMN ] },
                     "2" => { tenant_id_in: [ @studio.id.to_s ] } })

    assert_equal [ [ "tenant_id", "in", [ @studio.id.to_s ] ] ], conditions(applied)
    assert_equal 2, applied.result.count
  end

  # Inlined, it does not raise: it answers no rows, and dropping it would list them all.
  test "a single id past its column's type still matches nothing" do
    applied = form({ "0" => { tenant_id_eq: NUMBER_PAST_ANY_COLUMN } })

    assert_equal [ [ "tenant_id", "eq", NUMBER_PAST_ANY_COLUMN ] ], conditions(applied)
    assert_empty applied.result.to_a
  end

  test "a condition that is not a value is no filter" do
    applied = form({ "0" => { genre_eq: { "a" => "b" } } })

    assert_empty applied.filter_groups
  end

  test "a nested group or Ransack's c shape is no filter" do
    applied = form({ "0" => { g: { "0" => { name_cont: "Ana" } } },
                     "1" => { c: { "0" => { a: { "0" => { name: "name" } }, p: "eq", v: { "0" => { value: "Ana" } } } } } })

    assert_empty applied.filter_groups
    assert_equal 2, applied.result.count
  end

  test "a ransacker answers the operators of its type" do
    assert_equal [ [ "budget_band", "eq", "indie" ] ],
                 conditions(form({ "0" => { budget_band_eq: "indie", budget_band_cont: "in" } }))
  end

  test "groups a host reassigns after reading them are the ones applied" do
    applied = form({ "0" => { name_cont: "Bob", genre_eq: "Drama" } }, form_class: ReemittingPanelFilterForm)

    assert_equal [ [ "genre", "eq", "Drama" ] ], conditions(applied)
    assert_equal [ @ana ], applied.result.to_a
  end

  test "the attributes are the instance's, which hosts override" do
    applied = form({ "0" => { rating_gt: "7" } }, form_class: RatedPanelFilterForm)

    assert_equal [ [ "rating", "gt", "7" ] ], conditions(applied)
    assert_equal [ @ana ], applied.result.to_a
  end

  test "a quick search with a control character, a list or a hash searches nothing" do
    [ "A\u0000na", [ "Ana" ], { "x" => "Ana" } ].each do |value|
      searched = PanelFilterForm.new(Movie.all, ActionController::Parameters.new(q: { name_cont: value }))

      assert_nil searched.search_value, value.inspect
      assert_equal 2, searched.result.count
    end
  end

  # The panel takes its attributes in the view, or there is none: Ransack decides, as it did,
  # but nothing that breaks the query gets through.
  class SimpleOnlyFilterForm < Bali::FilterForm
    filter_attribute :genre, type: :select, simple: true, advanced: false, options: [ %w[Drama Drama] ]
  end

  test "a form that offers the panel no attribute lets any condition through but what breaks the query" do
    [ Bali::FilterForm, SimpleOnlyFilterForm ].each do |form_class|
      offered_none = form({ "0" => { name_cont: "Ana", genre_cont: "Dra" }, "1" => { name_eq: "A\u0000na" },
                            "2" => { g: { "0" => { name_eq: "Bob" } } } }, form_class: form_class)

      assert_equal [ [ "name", "cont", "Ana" ], [ "genre", "cont", "Dra" ] ], conditions(offered_none), form_class.name
      assert_equal [ @ana ], offered_none.result.to_a
    end
  end
end

# The two sources that bring a condition back on every visit.
class BaliFilterFormPanelConditionsStateTest < ActiveSupport::TestCase
  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  def setup
    Movie.create!(name: "Ana", genre: "Drama", studio: Tenant.create!(name: "Acme"))
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  def teardown
    Rails.cache = @original_cache
  end

  def build(params = {}, **options)
    BaliFilterFormPanelConditionsTest::PanelFilterForm.new(Movie.all, ActionController::Parameters.new(params), **options)
  end

  test "a saved view's condition the query cannot take is no filter" do
    view = View.new(1, "Broken", { "groupings" => { "0" => { "name_eq" => "A\u0000na" } }, "search_value" => "A\u0000" })
    applied = build({ saved_view: "1" }, saved_views_store: Store.new(view))

    assert_empty applied.filter_groups
    assert_nil applied.search_value
    assert_equal 1, applied.result.count
  end

  test "neither is one the filter cache restores" do
    build({ q: { g: { "0" => { name_eq: "A\u0000na" } } } }, storage_id: "movies")
    restored = build(storage_id: "movies", persist_enabled: true)

    assert_empty restored.filter_groups
    assert_equal 1, restored.result.count
  end
end
