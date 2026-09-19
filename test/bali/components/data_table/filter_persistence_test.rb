# frozen_string_literal: true

require "test_helper"

# The persistence checkbox lives exactly ONCE per listing: two `filter-persistence` controllers over
# the same storage_id overwrite each other's localStorage and cookie.
class BaliDataTableFilterPersistenceTest < ComponentTestCase
  def form(storage_id: nil, persist_enabled: false)
    Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                         storage_id: storage_id, persist_enabled: persist_enabled)
  end

  def render_data_table(filter_form:, slot: :filters_panel)
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: filter_form)) do |dt|
      slot == :filters_panel ? dt.with_filters_panel : dt.with_simple_filters(filters: sample_filters)
      dt.with_table { "<table><tbody><tr><td>Movie</td></tr></tbody></table>".html_safe }
    end
  end

  def sample_filters
    [ { attribute: :genre, collection: [ %w[Drama drama] ], blank: "All", label: "Genre" } ]
  end

  def test_the_filters_panel_yields_exactly_one_toggle
    render_data_table(filter_form: form(storage_id: "movies"))

    assert_selector('[data-controller="filter-persistence"]', count: 1)
  end

  def test_simple_filters_yield_exactly_one_toggle
    render_data_table(filter_form: form(storage_id: "movies"), slot: :simple_filters)

    assert_selector('[data-controller="filter-persistence"]', count: 1)
  end

  def test_no_toggle_without_a_storage_id
    render_data_table(filter_form: form)

    assert_no_selector('[data-controller="filter-persistence"]')
  end

  # With no filter control the checkbox means nothing: there is no filter state to remember.
  # `SimpleFilters#render?` is false with neither filters nor search, so declaring the slot is not
  # enough to paint the checkbox.
  def test_no_toggle_when_the_filters_slot_renders_nothing
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form(storage_id: "movies"))) do |dt|
      dt.with_simple_filters(filters: [])
      dt.with_table { "<table><tbody><tr><td>Movie</td></tr></tbody></table>".html_safe }
    end

    assert_no_selector('[data-controller="filter-persistence"]')
  end

  # The checkbox is a toolbar item of its own (and not part of the filters node), so the ⋯ menu can
  # treat it separately.
  def test_the_toggle_travels_in_its_own_overflow_item
    render_data_table(filter_form: form(storage_id: "movies"))

    assert_selector(
      '[data-toolbar-overflow-target="item"]' \
      "[data-toolbar-overflow-priority=\"#{Bali::DataTable::Component::OVERFLOW_PRIORITIES[:filter_persistence]}\"] " \
      '[data-controller="filter-persistence"]'
    )
  end

  # The slot RESOLVES the value (from the filter_form or from a host override): the DataTable
  # captures it there instead of re-deriving it, or the toolbar's checkbox would always read off.
  def test_the_resolved_persist_enabled_reaches_the_toolbar_control
    render_data_table(filter_form: form(storage_id: "movies", persist_enabled: true))

    assert_selector('[data-filter-persistence-enabled-value="true"]', count: 1)
  end

  # A host passing `storage_id:` straight to the slot (with no filter_form bringing it) has to keep
  # seeing the checkbox.
  def test_an_explicit_storage_id_on_the_slot_still_paints_the_toggle
    render_inline(Bali::DataTable::Component.new(url: "/movies")) do |dt|
      dt.with_simple_filters(filters: sample_filters, storage_id: "explicit_movies")
      dt.with_table { "<table><tbody><tr><td>Movie</td></tr></tbody></table>".html_safe }
    end

    assert_selector('[data-filter-persistence-storage-id-value="explicit_movies"]', count: 1)
  end
end

class ClearLinkMovieFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, options: [ %w[Drama drama] ], simple: true
  attribute :genre_eq
end

# The simple filters' "Clear" link is FOLLOWED, not looked at: asserting only its href lets through
# a link that clears nothing, which is exactly how this bug reached production (two tests pinned the
# bare URL as if it were the contract). Here the rendered href is parsed and handed to the
# FilterForm the way the server would with the click's request: what is asserted is the listing's
# RESULTING STATE, not the shape of the URL.
class BaliDataTableSimpleFiltersClearTest < ComponentTestCase
  CACHE_KEY = "clear_link_movie_filter_forms;;movies"

  def setup
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  def teardown
    Rails.cache = @original_cache
  end

  def sample_filters
    [ { attribute: :genre, collection: [ %w[Drama drama] ], blank: "All", label: "Genre" } ]
  end

  # The params the server would receive on following the "Clear" link's href.
  def params_from_clear_link
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
                    url: "/movies", filters: sample_filters, show_clear: true))
    href = page.find("a[aria-label='Clear'], a[aria-label='Limpiar']")[:href]
    ActionController::Parameters.new(Rack::Utils.parse_nested_query(URI(href).query.to_s))
  end

  def test_following_the_clear_link_leaves_the_listing_unfiltered
    ClearLinkMovieFilterForm.new(Movie.all, ActionController::Parameters.new(q: { genre_eq: "drama" }),
                                 storage_id: "movies")

    cleared = ClearLinkMovieFilterForm.new(Movie.all, params_from_clear_link,
                                           storage_id: "movies", persist_enabled: true)

    assert_empty(cleared.attributes.to_h.compact_blank,
                 "limpiar dejó filtros vivos: el listado sigue filtrado después del click")
  end

  def test_following_the_clear_link_drops_the_stored_state
    ClearLinkMovieFilterForm.new(Movie.all, ActionController::Parameters.new(q: { genre_eq: "drama" }),
                                 storage_id: "movies")
    assert(Rails.cache.read(CACHE_KEY), "premisa: el filtro quedó guardado")

    ClearLinkMovieFilterForm.new(Movie.all, params_from_clear_link,
                                 storage_id: "movies", persist_enabled: true)

    # Without deleting the cache the filter comes back on the NEXT visit, not on this one: the
    # symptom shifts by one request and the test above would let it through.
    assert_nil(Rails.cache.read(CACHE_KEY))
  end
end
