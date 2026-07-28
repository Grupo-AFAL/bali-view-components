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
end
