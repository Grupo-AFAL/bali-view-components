# frozen_string_literal: true

require "test_helper"

class KitchenSinkDemoPagesTest < ActionDispatch::IntegrationTest
  def setup
    @tenant = Tenant.create!(name: "Test Studio")
    @movie = @tenant.movies.create!(name: "Test Movie", status: 0)
  end

  def movie
    @movie
  end

  def test_dashboard_renders_the_dashboard_page_successfully
    get root_path
    assert_response :ok
  end

  def test_movies_get_movies_renders_the_index_page_successfully
    get movies_path
    assert_response :ok
  end

  def test_movies_get_movies_renders_with_filter_params
    get movies_path, params: { q: { name_cont: "Test" } }
    assert_response :ok
  end

  # El index canónico tiene TRES ramas de contenido (tabla seleccionable, grid de tarjetas y
  # Gantt) que comparten un partial. Sin pedirlas, una fecha nula, una clave i18n faltante o
  # un `with_content(scroll: true)` roto se publican en verde.
  def test_admin_movies_renders_every_display_mode_of_the_canonical_listing
    get admin_movies_path
    assert_response :ok
    assert_select "table.table"

    get admin_movies_path, params: { view: "grid" }
    assert_response :ok
    assert_select "h2.card-title"

    get admin_movies_path, params: { view: "timeline" }
    assert_response :ok
    assert_select ".gantt-chart-component"
  end

  def test_movies_renders_every_display_mode_of_the_shared_listing
    get movies_path, params: { view: "grid" }
    assert_response :ok
    assert_select "h2.card-title"

    get movies_path, params: { view: "timeline" }
    assert_response :ok
    assert_select ".gantt-chart-component"
  end

  # La página de referencia tiene que ejercitar TODA la familia de controles: sin dueño el
  # store no se resuelve y el dropdown desaparece sin romper nada.
  def test_admin_movies_renders_the_saved_views_dropdown
    get admin_movies_path
    assert_response :ok
    assert_select "[data-controller~='saved-views']"
  end

  # Ransack descarta un predicado combinado ENTERO cuando uno de sus campos no es
  # ransackable, sin levantar nada: la búsqueda respondía 200 y devolvía todo. Por eso la
  # aserción es sobre el SET, no sobre el status.
  def test_admin_movies_quick_search_narrows_the_result_set
    other = Tenant.create!(name: "Otro Estudio")
    other.movies.create!(name: "Otra Película", status: 0)

    get admin_movies_path, params: { q: { name_or_genre_or_studio_name_cont: "Test Studio" } }
    assert_response :ok
    assert_select "tbody tr", 1
    assert_select "tbody tr", text: /Otra Película/, count: 0
  end

  # Ransack castea con el tipo CRUDO de la columna, así que sobre un enum entero la etiqueta
  # "done" se volvía 0 — el código de `draft`— y el filtro devolvía los registros CONTRARIOS.
  # Este es el único test que recorre el shape exacto de URL que emite el builder de
  # Bali::Filters. La aserción es sobre el SET: un `assert_response :ok` pasaba con el bug.
  def test_admin_movies_filters_by_an_enum_label_from_the_filters_builder
    done_movie = @tenant.movies.create!(name: "Película Terminada", status: 1)

    get admin_movies_path, params: { q: { g: { "0" => { status_in: [ "done" ], m: "and" } } } }

    assert_response :ok
    assert_select "tbody tr", 1
    assert_select "tbody tr", text: /#{done_movie.name}/
    assert_select "tbody tr", text: /#{@movie.name}/, count: 0
  end

  def test_admin_movies_sorts_by_the_studio_association
    get admin_movies_path, params: { q: { s: "studio_name asc" } }
    assert_response :ok
    assert_select "th[aria-sort='ascending']", text: /Studio/
  end

  def test_admin_movies_groups_rows_when_the_group_by_control_is_used
    get admin_movies_path, params: { group_by: "status" }
    assert_response :ok
    assert_select "tr.bali-table-group-row"
  end

  def test_admin_movies_suspends_grouping_in_grid_mode_without_dropping_the_param
    # La agrupación solo aplica en la tabla: en tarjetas no hay banda de grupo que explique
    # el reordenamiento. El param igual tiene que viajar en el form de filtros, o buscar algo
    # desde tarjetas la borra.
    get admin_movies_path, params: { group_by: "status", view: "grid" }
    assert_response :ok
    assert_select "tr.bali-table-group-row", count: 0
    assert_select "input[name=group_by][value=status]"
  end

  def test_movies_get_movies_id_renders_the_show_page_successfully
    get movie_path(movie)
    assert_response :ok
  end

  def test_movies_get_movies_new_renders_the_new_page_successfully
    get new_movie_path
    assert_response :ok
  end

  def test_movies_get_movies_id_edit_renders_the_edit_page_successfully
    get edit_movie_path(movie)
    assert_response :ok
  end

  def test_settings_get_settings_renders_the_settings_page_successfully
    get settings_path
    assert_response :ok
  end

  def test_landing_page_get_landing_renders_the_landing_page_successfully
    get landing_path
    assert_response :ok
  end
end

# La persistencia de filtros solo existe completa a través de un REQUEST: cookie →
# `persist_enabled:` → restaurar → listado renderizado. Nada la recorría, y el tramo que la
# apagaba entera (el cache store del dummy) no lo cubría ningún test.
class KitchenSinkFilterPersistenceTest < ActionDispatch::IntegrationTest
  # El env de test corre con `:null_store`, donde toda escritura se pierde y toda lectura es
  # nil: un test de persistencia ahí pasa sin afirmar nada. Se cambia el store SOLO acá —
  # acoplar la suite entera a una caché global es justo lo que esto existe para no hacer.
  def setup
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @tenant = Tenant.create!(name: "Test Studio")
    @draft = @tenant.movies.create!(name: "Película Borrador", status: 0)
    @done = @tenant.movies.create!(name: "Película Terminada", status: 1)
  end

  def teardown
    Rails.cache = @original_cache
  end

  def filtered_params
    { q: { g: { "0" => { status_in: [ "done" ], m: "and" } } } }
  end

  def test_the_listing_restores_the_filters_of_the_previous_visit
    cookies["bali_persist_admin_movies"] = "1"
    get admin_movies_path, params: filtered_params
    assert_select "tbody tr", 1

    get admin_movies_path
    assert_response :ok
    assert_select "tbody tr", 1
    assert_select "tbody tr", text: /#{@done.name}/
  end

  # La caché se llama `class;context;storage_id`: sin `context:` un único key sirve a TODAS las
  # visitas del proceso y los filtros de uno se le restauran al siguiente. Con `:null_store`
  # esto no se veía porque no se guardaba nada.
  def test_a_visitor_does_not_restore_another_visitors_filters
    filtering = open_session
    filtering.cookies["bali_persist_admin_movies"] = "1"
    filtering.get admin_movies_path, params: filtered_params
    assert_not_includes filtering.response.body, @draft.name

    arriving = open_session
    arriving.cookies["bali_persist_admin_movies"] = "1"
    arriving.get admin_movies_path

    assert_includes arriving.response.body, @draft.name
    assert_includes arriving.response.body, @done.name
  end
end
