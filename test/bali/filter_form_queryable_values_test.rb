# frozen_string_literal: true

require "test_helper"

# #1351. Since #1346 a panel condition reaches Ransack only with a value the query can take; the
# flat attributes and the simple filters still handed it whatever arrived, from the URL, a saved
# view or the filter cache. A NUL byte breaks the query on both engines (Postgres: `string
# contains null byte`, SQLite: `unrecognized token`), and so does an id past its column inside an
# `_in`. The same rule applies to them now: such a value is no filter.
class BaliFilterFormQueryableValuesTest < ActiveSupport::TestCase
  class ValuesFilterForm < Bali::FilterForm
    attribute :name_cont
    attribute :id_in, default: []

    filter_attribute :genre, type: :select, simple: true, advanced: false, default: "Drama",
                             blank: "All genres", options: [ %w[Drama Drama], %w[Action Action] ]
    filter_attribute :tenant_id, type: :select, simple: true, advanced: false,
                                 input: :toggle_group, predicate: :in
    filter_attribute :rating, type: :number, simple: true, advanced: false
  end

  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  NUMBER_PAST_ANY_COLUMN = "9" * 30

  def setup
    @studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", genre: "Drama", rating: 8, studio: @studio)
    @bob = Movie.create!(name: "Bob", genre: "Action", rating: 6, studio: @studio)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  def teardown
    Rails.cache = @original_cache
  end

  def build(params = {}, **options)
    ValuesFilterForm.new(Movie.all, ActionController::Parameters.new(params), **options)
  end

  def with_saved_view(payload)
    build({ saved_view: "1" }, saved_views_store: Store.new(View.new(1, "Broken", payload)))
  end

  test "a flat attribute with a control character is no filter" do
    form = build({ q: { name_cont: "A\u0000na" } })

    assert_empty form.active_filters
    assert_equal 2, form.result.count
  end

  test "a flat list with an id past its column is no filter, and a list that fits still is" do
    assert_empty build({ q: { id_in: [ @ana.id.to_s, NUMBER_PAST_ANY_COLUMN ] } }).active_filters
    assert_equal [ @ana ], build({ q: { id_in: [ @ana.id.to_s ] } }).result.to_a
  end

  test "a simple filter with a control character is no filter" do
    form = build({ q: { genre_eq: "Dra\u0000ma" } })

    assert_empty form.active_filters
    assert_equal 2, form.result.count
  end

  test "a simple list with an id past its column is no filter, and a list that fits still is" do
    Movie.create!(name: "Cleo", genre: "Drama", studio: Tenant.create!(name: "Other"))

    assert_empty build({ q: { tenant_id_in: [ NUMBER_PAST_ANY_COLUMN ] } }).active_filters
    assert_equal [ @ana, @bob ], build({ q: { tenant_id_in: [ @studio.id.to_s ] } }).result.order(:name).to_a
  end

  test "each end of a number range answers for itself" do
    form = build({ q: { rating_gteq: "7\u0000", rating_lteq: "7" } })

    assert_equal({ "rating_lteq" => "7" }, form.active_filters)
    assert_equal [ @bob ], form.result.to_a
  end

  test "a saved view's flat attribute or simple filter that is not a value is no filter" do
    [ { "attributes" => { "name_cont" => { "a" => "Ana" } } },
      { "attributes" => { "name_cont" => [ "Ana" ] } },
      { "simple_filters" => { "genre_eq" => { "a" => "Drama" } } },
      { "simple_filters" => { "genre_eq" => %w[Drama Action] } } ].each do |payload|
      form = with_saved_view(payload)

      assert_empty form.active_filters, payload.inspect
      assert_equal 2, form.result.count
    end
  end

  # Pills whose list the form drops would render and never filter, so it fails when the class
  # is defined, like an `auto_submit:` nobody reads. The deprecated DSL defaults to `:eq` too.
  test "a toggle group on a predicate that takes no list raises when the class is defined" do
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) { filter_attribute :genre, type: :select, simple: true, input: :toggle_group }
    end
    assert_match(/predicate: :eq does not take/, error.message)

    assert_raises(ArgumentError) do
      Bali.deprecator.silence { Class.new(Bali::FilterForm) { simple_filter :genre, type: :toggle_group } }
    end
    Class.new(Bali::FilterForm) do
      filter_attribute :genre, type: :select, simple: true, input: :toggle_group, predicate: :not_in
    end
  end

  test "neither is one the filter cache restores" do
    build({ q: { name_cont: "A\u0000na", genre_eq: "Dra\u0000ma" } }, storage_id: "movies")
    restored = build(storage_id: "movies", persist_enabled: true)

    assert_empty restored.active_filters
    assert_equal 2, restored.result.count
  end
end

class BaliFilterFormQueryableValuesRenderTest < ComponentTestCase
  # Painted as absent, the select would show its `default:` over a listing it does not filter.
  test "a simple filter's value the query cannot take is painted as its blank, not as its default" do
    form = BaliFilterFormQueryableValuesTest::ValuesFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "Dra\u0000ma" })
    )
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/movies", filters: form.simple_filters_config))

    assert_selector "select[name='q[genre_eq]'] option:first-child[value='']", text: "All genres"
    assert_no_selector "select[name='q[genre_eq]'] option[selected]"
  end
end
