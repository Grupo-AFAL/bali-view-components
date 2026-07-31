# frozen_string_literal: true

require "test_helper"

class BaliDataTableSavedViewsComponentTest < ComponentTestCase
  FakeStore = Struct.new(:views) do
    def list = views
    def find(id) = views.find { |view| view.id.to_s == id.to_s }
  end

  SavedView = Struct.new(:id, :name, :payload, keyword_init: true)

  def store
    @store ||= FakeStore.new([
      SavedView.new(id: 1, name: "Activos", payload: { "attributes" => { "name_i_cont" => "a" } }),
      SavedView.new(id: 2, name: "Míos", payload: { "attributes" => {} })
    ])
  end

  def form(params = ActionController::Parameters.new, views_store: store)
    Bali::FilterForm.new(Movie.all, params, saved_views_store: views_store)
  end

  def render_component(filter_form, **options)
    render_inline(Bali::DataTable::SavedViews::Component.new(
      filter_form: filter_form, url: "/vistas", base_url: "/listado", **options
    ))
  end

  def test_does_not_render_without_a_store
    render_component(Bali::FilterForm.new(Movie.all, ActionController::Parameters.new))
    assert_no_selector "[data-controller='saved-views']"
  end

  def test_the_popover_opens_to_the_left_now_that_the_control_lives_on_the_left
    # Anclado al borde derecho de su trigger (`dropdown-end`) el panel abría hacia afuera de
    # la fila a la que pertenece, desde que el control se mudó al grupo izquierdo.
    render_component(form)

    assert_selector "[data-controller='saved-views'].dropdown"
    assert_no_selector "[data-controller='saved-views'].dropdown-end"
  end

  def test_renders_personal_views_with_apply_urls_and_the_save_form
    render_component(form)

    assert_selector "[data-controller='saved-views']"
    assert_selector "a[href='/listado?saved_view=1']", text: "Activos"
    assert_selector "a[href='/listado?saved_view=2']", text: "Míos"
    # Form de guardar: POST a la URL de la app con el payload serializado en un hidden.
    assert_selector "form[action='/vistas'] input[name='payload']", visible: :all
    # Renombrar/borrar apuntan a la ruta del recurso.
    assert_selector "form[action='/vistas/1']", visible: :all
  end

  def test_the_button_shows_the_applied_view_name
    applied = form(ActionController::Parameters.new(saved_view: "1"))
    render_component(applied)

    assert_selector "button", text: "Activos"
    assert_selector "a[href='/listado?saved_view=1'].active"
  end

  def test_default_views_render_in_their_own_suggested_section
    render_component(form, default_views: [ { name: "En riesgo", url: "/listado?q%5Bhealth_eq%5D=rojo" } ])

    assert_selector "a[href='/listado?q%5Bhealth_eq%5D=rojo']", text: "En riesgo"
  end

  def test_base_url_with_existing_query_appends_with_ampersand
    render_inline(Bali::DataTable::SavedViews::Component.new(
      filter_form: form, url: "/vistas", base_url: "/listado?vista=tabla"
    ))

    assert_selector "a[href='/listado?vista=tabla&saved_view=1']"
  end

  # --- Store default del engine (saved_views_store: :default) ---

  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def default_form
    Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                         storage_id: "movies_index", saved_views_store: :default,
                         saved_views_owner: owner)
  end

  def test_default_store_resolves_to_the_engine_storage_scoped_to_the_owner
    Bali::SavedView.create!(owner: owner, storage_id: "movies_index", name: "Guardada",
                            payload: { "attributes" => {} })
    Bali::SavedView.create!(owner: User.create!(name: "Otra"), storage_id: "movies_index",
                            name: "Ajena", payload: { "attributes" => {} })

    form = default_form

    assert_predicate form, :saved_views_enabled?
    assert_equal [ "Guardada" ], form.saved_views.map(&:name)
  end

  def test_default_store_needs_owner_and_storage_id_or_stays_off
    no_owner = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                    storage_id: "movies_index", saved_views_store: :default)
    no_storage = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                      saved_views_store: :default,
                                      saved_views_owner: User.create!(name: "Beto"))

    assert_not no_owner.saved_views_enabled?
    assert_not no_storage.saved_views_enabled?
  end

  def test_the_data_table_slot_defaults_the_url_to_the_engine_routes
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: default_form)) do |dt|
      dt.with_saved_views
      dt.with_table { "".html_safe }
    end

    # POST del form de guardar contra las rutas del engine montado, con el storage_id
    # del propio FilterForm en el query string.
    assert_selector "form[action='/bali/saved_views?storage_id=movies_index']", visible: :all
  end

  def test_saved_views_and_the_column_selector_agree_on_the_listing_target
    # El JS de saved-views encuentra al selector de columnas comparando ESTA cadena exacta,
    # y lee sus columnas guardadas de ESTA llave: si las dos derivaciones se separan,
    # guardar una vista pierde las columnas sin fallar en ningún lado.
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: default_form)) do |dt|
      dt.with_saved_views
      dt.with_column_selector { |cs| cs.with_column(index: 0, label: "Nombre") }
      dt.with_table { "".html_safe }
    end

    assert_selector "[data-saved-views-table-value='#movies_index table']"
    assert_selector "[data-column-selector-table-value='#movies_index table']"
    assert_selector "[data-saved-views-storage-key-value='bali:columns:movies_index']"
    assert_selector "[data-column-selector-storage-key-value='bali:columns:movies_index']"
  end

  def test_applying_a_view_keeps_the_current_display_mode
    # El view switch preserva `saved_view` a propósito; la dirección inversa tiene que ser
    # simétrica — aplicar una vista no puede sacar al usuario del modo que está mirando.
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form,
                                                 display_mode: :grid)) do |dt|
      dt.with_saved_views(url: "/vistas")
      dt.with_grid { "".html_safe }
    end

    assert_selector "a[href='/listado?view=grid&saved_view=1']"
  end

  def test_without_a_display_mode_the_apply_url_stays_bare
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form)) do |dt|
      dt.with_saved_views(url: "/vistas")
      dt.with_table { "".html_safe }
    end

    assert_selector "a[href='/listado?saved_view=1']"
  end

  def test_the_columns_imposed_by_the_applied_view_travel_to_the_controller
    # Sin selector en el DOM (modos que no son tabla) el JS caía a localStorage, que es la
    # memoria ANTERIOR a la vista: guardar desde tarjetas persistía columnas que el usuario
    # no estaba viendo.
    columns_store = FakeStore.new([
      SavedView.new(id: 5, name: "Compacta", payload: { "attributes" => {}, "columns" => [ 1, 3 ] })
    ])
    render_component(form(ActionController::Parameters.new(saved_view: "5"), views_store: columns_store))

    assert_selector "[data-saved-views-server-columns-value='[1,3]']"
  end

  def test_the_slot_without_url_nor_storage_id_does_not_render_the_dropdown
    form_without_storage = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                                saved_views_store: store)
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form_without_storage)) do |dt|
      dt.with_saved_views
      dt.with_table { "".html_safe }
    end

    assert_no_selector "[data-controller='saved-views']"
  end

  # --- Vista activa por coincidencia de ESTADO (la persistencia deja la URL limpia) ---

  class NamedMovieFilterForm < Bali::FilterForm
    attribute :name_i_cont, :string
  end

  def named_form(params = ActionController::Parameters.new, views_store: store)
    NamedMovieFilterForm.new(Movie.all, params, saved_views_store: views_store)
  end

  def test_a_personal_view_matching_the_current_state_is_active_without_the_url_param
    # El payload de "Activos" (name_i_cont: "a") describe el estado actual del form aunque
    # la URL no traiga ?saved_view — exactamente lo que pasa tras una restauración de
    # persistencia o al navegar de regreso.
    matching = named_form(ActionController::Parameters.new(q: { name_i_cont: "a" }))
    render_component(matching)

    assert_selector "a[href='/listado?saved_view=1'].active"
    assert_selector "button", text: "Activos"
  end

  def test_a_default_view_whose_query_matches_the_state_is_active
    only_defaults = named_form(ActionController::Parameters.new(q: { name_i_cont: "a" }),
                               views_store: FakeStore.new([]))
    render_component(only_defaults,
                     default_views: [ { name: "Con a", url: "/listado?q%5Bname_i_cont%5D=a" },
                                      { name: "Otra", url: "/listado?q%5Bname_i_cont%5D=z" } ])

    assert_selector "a.active", text: "Con a"
    assert_no_selector "a.active", text: "Otra"
    assert_selector "button", text: "Con a"
  end

  def test_the_view_applied_by_url_wins_over_state_matching
    # saved_view=2 aplicado explícitamente gana la marca aunque el estado también
    # coincida con otra vista: una sola activa, sin doble marca.
    applied = named_form(ActionController::Parameters.new(saved_view: "2"))
    render_component(applied)

    assert_selector "a[href='/listado?saved_view=2'].active"
    assert_no_selector "a[href='/listado?saved_view=1'].active"
    assert_selector "button", text: "Míos"
  end

  # --- R5 (ronda adversarial): la marca activa no puede MENTIR ---

  def test_a_view_whose_payload_normalizes_to_empty_never_matches_by_state
    # Caso insignia de B2 ("guardo mi arreglo de columnas"): payload sin filtros. Describe el
    # estado limpio, así que casaba en CADA visita y se marcaba activa aunque sus columnas no
    # estuvieran aplicadas (columns solo se aplica con ?saved_view=).
    columns_only = FakeStore.new([
      SavedView.new(id: 9, name: "Compacta", payload: { "attributes" => {}, "columns" => [ 0, 1 ] })
    ])
    render_component(named_form(ActionController::Parameters.new, views_store: columns_only))

    assert_no_selector "a.active"
    # El botón conserva su etiqueta genérica: no hay vista que nombrar.
    assert_selector "button", text: I18n.t("view_components.bali.data_table.saved_views.button_label")

    # Aplicada por URL sí se reconoce: ahí el estado de la vista realmente está impuesto.
    render_component(named_form(ActionController::Parameters.new(saved_view: "9"),
                                views_store: columns_only))
    assert_selector "a[href='/listado?saved_view=9'].active"
  end

  def test_a_shortcut_stays_marked_after_the_builder_round_trip_adds_the_default_m
    # El builder re-emite q[g][0][m]=or aunque la URL del atajo no lo trajera: sin normalizar
    # ese combinador no-op, el atajo se desmarcaba tras aplicar el popover o buscar una vez.
    state = ActionController::Parameters.new(q: { g: { "0" => { name_i_cont: "a", m: "or" } } })
    render_component(named_form(state, views_store: FakeStore.new([])),
                     default_views: [ { name: "Con a", url: "/listado?q%5Bg%5D%5B0%5D%5Bname_i_cont%5D=a" } ])

    assert_selector "a.active", text: "Con a"
  end

  def test_a_shortcut_matches_on_the_groupings_shape_used_by_real_apps
    # Los atajos reales viajan como q[g][0][attr_eq] (no como attributes planos).
    state = ActionController::Parameters.new(q: { g: { "0" => { name_i_cont: "rojo" } } })
    render_component(named_form(state, views_store: FakeStore.new([])),
                     default_views: [
                       { name: "En rojo", url: "/listado?q%5Bg%5D%5B0%5D%5Bname_i_cont%5D=rojo" },
                       { name: "Otro", url: "/listado?q%5Bg%5D%5B0%5D%5Bname_i_cont%5D=verde" }
                     ])

    assert_selector "a.active", text: "En rojo"
    assert_no_selector "a.active", text: "Otro"
  end

  def test_renaming_inputs_get_unique_ids
    render_component(form)

    ids = page.native.css("input[type='text']").map { |input| input["id"] }.compact
    assert_equal ids.uniq.size, ids.size, "los ids de los inputs de nombre deben ser únicos"
  end
end
