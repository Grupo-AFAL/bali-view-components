# frozen_string_literal: true

require "test_helper"

class BaliDataTableViewSwitchControlComponentTest < ComponentTestCase
  def component(current: nil, current_params: {}, **options)
    Bali::DataTable::ViewSwitchControl::Component.new(
      url: "/movies", current: current, current_params: current_params, **options
    )
  end

  # Las vistas se declaran ANTES de renderizar, igual que hace el slot del DataTable
  # (`block&.call(component)`): el bloque de contenido de ViewComponent llegaría tarde,
  # después de que `render?` ya decidió.
  def render_switch(**kwargs)
    switch = component(**kwargs)
    switch.with_view(name: "Tabla", icon: "list", value: :table)
    switch.with_view(name: "Tarjetas", icon: "grid", value: :grid)
    render_inline(switch)
  end

  def test_does_not_render_without_views
    render_inline(component)
    assert_no_selector(".view-switch-component")
  end

  def test_renders_one_link_per_declared_view
    render_switch
    assert_selector("a.join-item", count: 2)
    assert_selector("a[href='/movies?view=table']", text: "Tabla")
    assert_selector("a[href='/movies?view=grid']", text: "Tarjetas")
  end

  def test_hrefs_preserve_q_and_saved_view_and_drop_page
    # Cambiar de modo de visualización es NAVEGACIÓN: los filtros y la vista guardada
    # aplicada sobreviven; la paginación vuelve a la primera página.
    render_switch(current_params: { "q" => { "name_cont" => "matrix" }, "saved_view" => "7", "page" => "3" })

    assert_selector("a[href*='view=grid'][href*='saved_view=7'][href*='name_cont']")
    assert_no_selector("a[href*='page=3']")
  end

  def test_hrefs_drop_the_one_shot_commands
    render_switch(current_params: { "clear_filters" => "true", "clear_search" => "true", "group_by" => "genre" })

    assert_no_selector("a[href*='clear_filters']")
    assert_no_selector("a[href*='clear_search']")
    assert_selector("a[href*='group_by=genre']")
  end

  def test_a_url_that_already_carries_a_query_string_is_merged_not_concatenated
    # `"#{url}?#{query}"` daba `/movies?scope=archived?view=grid`, que Rack parsea como un
    # solo `scope` corrupto y sin `view`: el click no cambiaba de vista.
    switch = Bali::DataTable::ViewSwitchControl::Component.new(
      url: "/movies?scope=archived", current_params: { "q" => { "name_cont" => "matrix" } }
    )
    switch.with_view(name: "Tabla", icon: "list", value: :table)
    switch.with_view(name: "Tarjetas", icon: "grid", value: :grid)
    render_inline(switch)

    href = page.native.css("a").map { |link| link["href"] }.find { |url| url.include?("view=grid") }
    assert_equal 1, href.count("?")
    parsed = Rack::Utils.parse_nested_query(href.split("?", 2).last)
    assert_equal "archived", parsed["scope"]
    assert_equal "grid", parsed["view"]
  end

  def test_marks_the_current_view_as_active
    render_switch(current: :grid)

    assert_selector("a.btn-active.btn-primary[href*='view=grid'][aria-current='page']")
    assert_selector("a.btn-outline[href*='view=table']:not([aria-current])")
  end

  def test_unknown_view_falls_back_to_the_first_declared
    # El `?view=` crudo nunca llega al contenido sin validarse: un valor desconocido cae a
    # la primera vista en vez de dejar el listado vacío.
    render_switch(current: :roadmap)
    assert_selector("a.btn-active[href*='view=table']")
  end

  def test_nil_current_falls_back_to_the_first_declared
    render_switch
    assert_selector("a.btn-active[href*='view=table']")
  end

  def test_custom_param_name
    render_switch(param: :mode)
    assert_selector("a[href='/movies?mode=table']")
    assert_selector("a[href='/movies?mode=grid']")
  end

  def test_explicit_href_is_left_to_the_path_autodetection
    # Una vista que vive en OTRA ruta no la marca el control: la autodetección por path de
    # Bali::ViewSwitch es la que sabe si estamos parados encima.
    switch = component
    switch.with_view(name: "Tabla", icon: "list", value: :table)
    switch.with_view(name: "Estudios", icon: "calendar", href: "/studios")

    with_request_url "/studios" do
      render_inline(switch)
    end

    assert_selector("a.btn-active[href='/studios']")
  end

  def test_explicit_active_overrides_the_current_value
    switch = component(current: :table)
    switch.with_view(name: "Tabla", icon: "list", value: :table, active: false)
    switch.with_view(name: "Tarjetas", icon: "grid", value: :grid)
    render_inline(switch)

    assert_selector("a.btn-outline[href*='view=table']")
  end

  def test_forwards_view_switch_options
    render_switch(icon_only: true, size: :xs)
    assert_selector("a.btn-square.btn-xs[title='Tabla']")
  end

  def test_labels_the_group_for_screen_readers
    render_switch
    assert_selector("div[role=group][aria-label='Views']")

    I18n.with_locale(:es) do
      render_switch
      assert_selector("div[role=group][aria-label='Vistas']")
    end
  end

  def test_view_without_value_or_href_raises
    error = assert_raises(ArgumentError) { component.with_view(name: "X", icon: "list") }
    assert_match(/value:/, error.message)
  end
end
