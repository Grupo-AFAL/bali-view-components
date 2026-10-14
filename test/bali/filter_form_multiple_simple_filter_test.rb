# frozen_string_literal: true

require "test_helper"

# #1440. `multiple: true` is the simple row's filter for several values out of a list too long
# for `toggle_group` pills: a slim_select that sends `q[genre_in][]`, which reaches Ransack as the
# list it is — and so does every reader of a simple filter's value after it.
class BaliFilterFormMultipleSimpleFilterTest < ActiveSupport::TestCase
  class GenresFilterForm < Bali::FilterForm
    filter_attribute :genre, type: :select, simple: true, advanced: false, multiple: true,
                             predicate: :in, blank: "All genres",
                             options: [ %w[Drama Drama], %w[Action Action], %w[Comedy Comedy] ]
    filter_attribute :status, type: :select, simple: true, advanced: false, multiple: true,
                              predicate: :in, options: Movie.statuses.keys.map { |s| [ s, s ] }
  end

  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @action = Movie.create!(name: "Action", genre: "Action", studio: studio)
    @comedy = Movie.create!(name: "Comedy", genre: "Comedy", studio: studio, status: :done)
    @drama = Movie.create!(name: "Drama", genre: "Drama", studio: studio)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  def teardown
    Rails.cache = @original_cache
  end

  def build(params = {}, **options)
    GenresFilterForm.new(Movie.all, ActionController::Parameters.new(params), **options)
  end

  test "a select declared multiple renders as a multiple slim_select" do
    genre = GenresFilterForm.defined_simple_filters.first

    assert_equal [ :slim_select, true, :in ], genre.values_at(:type, :multiple, :predicate)
  end

  # The leading blank is the hidden field Rails sends with every multiple select.
  test "the list the row sends filters by each of its values" do
    form = build({ q: { genre_in: [ "", "Drama", "Comedy" ] } })

    assert_equal [ @comedy, @drama ], form.result.order(:name).to_a
    assert_equal %w[Drama Comedy], form.simple_filters_config.first[:value]
    assert_equal [ [ "q[genre_in][]", "Drama" ], [ "q[genre_in][]", "Comedy" ] ],
                 Bali::Filters::ActiveFilterParams.for_filter_form(form)
  end

  test "enum labels in the list are cast like a single value is" do
    assert_equal [ @comedy ], build({ q: { status_in: [ "", "done" ] } }).result.to_a
  end

  # Every chip removed still sends the hidden blank: the request says "no filter" and the cache
  # does not hand back the values the user just took off. The cache is seeded through a saved
  # view, the one path that stored a list before #1440.
  test "a list emptied of its chips overwrites the filter cache instead of restoring it" do
    build({ saved_view: "1" }, storage_id: "movies",
                               saved_views_store: Store.new(View.new(1, "Drama", { "simple_filters" => { "genre_in" => [ "Drama" ] } })))
    emptied = build({ q: { genre_in: [ "" ] } }, storage_id: "movies", persist_enabled: true)

    assert_equal 3, emptied.result.count
  end

  test "the filter cache and a saved view bring the list back" do
    saved = build({ q: { genre_in: %w[Drama Comedy] } }, storage_id: "movies")
    restored = build({}, storage_id: "movies", persist_enabled: true)
    applied = build({ saved_view: "1" },
                    saved_views_store: Store.new(View.new(1, "Two genres", saved.current_view_payload)))

    [ restored, applied ].each do |form|
      assert_equal [ @comedy, @drama ], form.result.order(:name).to_a
      assert_equal %w[Drama Comedy], form.simple_filters_config.first[:value]
    end
  end

  test "an instance-level slim_select hash takes the same list" do
    form = Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_in: %w[Action] }),
      simple_filters: [ { attribute: :genre, type: :slim_select, multiple: true, predicate: :in,
                          collection: [ %w[Action Action] ] } ]
    )

    assert_equal [ @action ], form.result.to_a
  end

  test "multiple: on a predicate that takes no list raises when the class is defined" do
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) { filter_attribute :genre, type: :select, simple: true, multiple: true }
    end

    assert_match(/multiple: true sends a list, which predicate: :eq does not take/, error.message)
  end

  test "multiple: anywhere but the simple row's slim_select raises when the class is defined" do
    { { input: :toggle_group } => /this one is :toggle_group/,
      { input: :select } => /this one is :select/,
      { simple: false } => /this one is not a simple filter/ }.each do |options, message|
      error = assert_raises(ArgumentError, options.inspect) do
        Class.new(Bali::FilterForm) do
          filter_attribute :genre, type: :select, simple: true, multiple: true, predicate: :in, **options
        end
      end

      assert_match message, error.message
    end
  end
end

class BaliFilterFormMultipleSimpleFilterRenderTest < ComponentTestCase
  test "the row paints a declared multiple as chips holding every value of the request" do
    form = BaliFilterFormMultipleSimpleFilterTest::GenresFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_in: [ "", "Drama", "Comedy" ] })
    )
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/movies", filters: form.simple_filters_config))

    assert_selector "select[multiple][name='q[genre_in][]']"
    assert_equal %w[Drama Comedy], page.all("select[name='q[genre_in][]'] option[selected]").map(&:value)
  end
end
