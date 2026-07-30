# frozen_string_literal: true

require "test_helper"

# El marcador de persistencia vive UNA sola vez por listado: dos controladores
# `filter-persistence` sobre el mismo storage_id se pisan el localStorage y la cookie.
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

  # Sin control de filtros el marcador no significa nada: no hay estado de filtros que
  # recordar. `SimpleFilters#render?` es false sin filtros ni búsqueda, así que declarar el
  # slot no alcanza para pintar el marcador.
  def test_no_toggle_when_the_filters_slot_renders_nothing
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form(storage_id: "movies"))) do |dt|
      dt.with_simple_filters(filters: [])
      dt.with_table { "<table><tbody><tr><td>Movie</td></tr></tbody></table>".html_safe }
    end

    assert_no_selector('[data-controller="filter-persistence"]')
  end

  # El marcador es un item propio de la toolbar (y no parte del nodo de filtros), así que el
  # menú ⋯ puede tratarlo aparte.
  def test_the_toggle_travels_in_its_own_overflow_item
    render_data_table(filter_form: form(storage_id: "movies"))

    assert_selector(
      '[data-toolbar-overflow-target="item"]' \
      "[data-toolbar-overflow-priority=\"#{Bali::DataTable::Component::OVERFLOW_PRIORITIES[:filter_persistence]}\"] " \
      '[data-controller="filter-persistence"]'
    )
  end

  # El valor lo RESUELVE el slot (del filter_form o de un override del host): el DataTable lo
  # captura ahí en vez de re-derivarlo, o el marcador de la toolbar quedaría siempre apagado.
  def test_the_resolved_persist_enabled_reaches_the_toolbar_control
    render_data_table(filter_form: form(storage_id: "movies", persist_enabled: true))

    assert_selector('[data-filter-persistence-enabled-value="true"]', count: 1)
  end

  # Un host que pasa `storage_id:` directo al slot (sin filter_form que lo traiga) tiene que
  # seguir viendo el marcador.
  def test_an_explicit_storage_id_on_the_slot_still_paints_the_toggle
    render_inline(Bali::DataTable::Component.new(url: "/movies")) do |dt|
      dt.with_simple_filters(filters: sample_filters, storage_id: "explicit_movies")
      dt.with_table { "<table><tbody><tr><td>Movie</td></tr></tbody></table>".html_safe }
    end

    assert_selector('[data-filter-persistence-storage-id-value="explicit_movies"]', count: 1)
  end
end
