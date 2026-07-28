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

  def test_the_slot_without_url_nor_storage_id_does_not_render_the_dropdown
    form_without_storage = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                                saved_views_store: store)
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form_without_storage)) do |dt|
      dt.with_saved_views
      dt.with_table { "".html_safe }
    end

    assert_no_selector "[data-controller='saved-views']"
  end
end
