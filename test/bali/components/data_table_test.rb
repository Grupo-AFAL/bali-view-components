# frozen_string_literal: true

require "test_helper"

# Form con agrupación declarada, para el round-trip de preserved_params.
class GroupableDataTableFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Género"

  attribute :genre_eq
end

class BaliDataTableComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  def component
    Bali::DataTable::Component.new(url: "/", **@options)
  end

  def filter_attributes
    [ { key: :name, type: :text, label: "Name" } ]
  end

  def test_renders_without_summary
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("div.filters")
    assert_selector("div.table-component")
  end

  def test_renders_with_summary
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_summary { "<p>Summary</p>".html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("div.filters")
    assert_selector("div.table-component")
    assert_selector("p", text: "Summary")
  end

  def test_renders_without_filters_panel
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_no_selector("div.filters")
    assert_selector("div.table-component")
  end

  def test_renders_toolbar_buttons
    render_inline(component) do |c|
      c.with_toolbar_button { '<button class="btn">Export</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("button.btn", text: "Export")
  end

  # --- Grouping (group_by control + round-trip) ---

  def grouping_filter_form(group_by: "genre", view: nil, **options)
    Bali::FilterForm.new(
      Movie.all,
      ActionController::Parameters.new(
        q: ActionController::Parameters.new({}), group_by: group_by, view: view
      ),
      simple_filters: [ { attribute: :genre, collection: [ %w[Action Action] ], blank: "All" } ],
      group_by_attributes: %i[genre status],
      **options
    )
  end

  def test_renders_group_by_control_when_filter_form_declares_group_by
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector(".dropdown a[href*='group_by=genre']")
    assert_selector(".dropdown a[href*='group_by=status']")
  end

  def test_does_not_render_group_by_control_without_declared_attributes
    filter_form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(q: {}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: filter_form)) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector("a[href*='group_by=']")
  end

  def test_simple_filters_preserve_active_group_by_as_hidden_field
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_filters_panel_preserves_active_group_by_as_hidden_field
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_no_group_by_hidden_field_when_grouping_inactive
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(group_by: nil))) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector("input[type=hidden][name=group_by]", visible: :all)
  end

  # --- Suspensión en tarjetas: se esconde el control, NO el param ---

  def test_grid_mode_keeps_the_group_by_hidden_field
    # ANTI-REGRESIÓN: el hidden field gatea por ESTADO (`group_by_active?`), no por
    # APLICACIÓN. Si alguien lo "arregla" a `group_by_applied?`, buscar algo estando en
    # tarjetas borra la agrupación y volver a la tabla ya no la encuentra.
    form = grouping_filter_form(view: "grid")
    assert(form.group_by_suspended?, "el form tiene que estar suspendido para que el test valga")

    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: form, display_mode: :grid)
    ) do |c|
      c.with_simple_filters
      c.with_grid { '<div class="grid-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_the_suspended_control_offers_no_grouping_links
    render_inline(
      Bali::DataTable::Component.new(
        url: "/movies", filter_form: grouping_filter_form(view: "grid"), display_mode: :grid
      )
    ) do |c|
      c.with_grid { '<div class="grid-component"></div>'.html_safe }
    end

    assert_no_selector(".dropdown a[href*='group_by=']")
  end

  def test_group_by_control_renders_again_back_in_table_mode
    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(view: "table"))
    ) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector(".dropdown a[href*='group_by=status']")
  end

  def test_raises_when_the_view_param_disagrees_with_the_filter_form
    # Desincronizados no hay NADA visible que lo delate: la tabla se ve igual y la suspensión
    # decide al revés (mirando un param que el view switch nunca escribe).
    error = assert_raises(ArgumentError) do
      Bali::DataTable::Component.new(
        url: "/movies", filter_form: grouping_filter_form, view_param: :modo
      )
    end
    assert_match("view_param", error.message)
  end

  def test_does_not_raise_on_a_custom_view_param_shared_with_the_filter_form
    component = Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form(view_param: :modo), view_param: :modo
    )
    assert(component)
  end

  def test_does_not_raise_on_a_custom_view_param_when_the_listing_has_no_grouping
    # Sin agrupación declarada el modo de visualización no cambia ninguna decisión del form.
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(q: {}))
    assert(Bali::DataTable::Component.new(url: "/movies", filter_form: form, view_param: :modo))
  end

  def test_raises_when_the_listing_renders_a_mode_the_form_never_heard_about
    # El modo se deriva DOS veces: el DataTable lo resuelve contra las vistas declaradas y el
    # form lo lee de la URL. Sin `?view=`, un listado que declara las tarjetas PRIMERO pinta
    # tarjetas mientras el form —viendo nil— aplica la agrupación igual: las tarjetas vuelven
    # reordenadas sin ninguna banda que lo explique.
    # Las dos clases: el bloque del host se evalúa dentro del render, así que según quién esté
    # en la pila ActionView puede envolver el ArgumentError en un Template::Error.
    error = assert_raises(ArgumentError, ActionView::Template::Error) do
      render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
        c.with_view_switch do |switch|
          switch.with_view(name: "Cards", icon: "grid", value: :grid)
          switch.with_view(name: "Table", icon: "list", value: :table)
        end
        c.with_grid { c.display_mode.to_s.html_safe }
      end
    end
    assert_match("display_mode", error.message)
  end

  def test_does_not_raise_when_the_host_hands_the_form_the_same_mode
    component = Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form(display_mode: :grid), display_mode: :grid
    )
    render_inline(component) do |c|
      c.with_view_switch do |switch|
        switch.with_view(name: "Cards", icon: "grid", value: :grid)
        switch.with_view(name: "Table", icon: "list", value: :table)
      end
      c.with_grid { c.display_mode.to_s.html_safe }
    end

    assert_text("grid")
  end

  def test_does_not_raise_on_an_unknown_view_param
    # Un `?view=` desconocido lo puede tipear un usuario: el listado cae a la primera vista y
    # el form suspende. Es un límite conocido y sin daño — un 500 no es la respuesta a un typo.
    component = Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form(view: "bogus")
    )
    render_inline(component) do |c|
      c.with_view_switch do |switch|
        switch.with_view(name: "Table", icon: "list", value: :table)
      end
      c.with_table { c.display_mode.to_s.html_safe }
    end

    assert_text("table")
  end

  def test_a_suspended_grouping_leaves_the_control_in_place_but_inert
    # Esconderlo movía la fila entera al cambiar de modo, y el cartel que lo explicaba ocupaba
    # una franja permanente para decir lo que un botón apagado ya dice.
    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(view: "grid"))
    ) do |c|
      c.with_grid { "".html_safe }
    end

    assert_selector("button.btn-disabled[title*='Table']", text: /Group by/)
    assert_no_selector("[data-dropdown-target='trigger']", text: /Group by/)
  end

  def test_explicit_preserved_params_do_not_drop_the_active_group_by
    # Antes eran excluyentes: un host que preservaba sus propios params tiraba la
    # agrupación en cada submit de filtros o búsqueda.
    form = GroupableDataTableFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "genre")
    )
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel(preserved_params: { view_mode: "cards" })
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='genre']", visible: :all)
    assert_selector("input[name='view_mode'][value='cards']", visible: :all)
  end

  # --- Superficie: la trae el slot de contenido, no el host ni la toolbar ---

  def test_with_table_brings_its_own_surface_and_scroll_wrapper
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector(
      "div.data-table-component div.card > div.card-body > div.overflow-x-auto > div.table-component"
    )
  end

  def test_with_grid_renders_without_surface
    render_inline(component) do |c|
      c.with_grid { '<div class="cards"></div>'.html_safe }
    end

    # Las tarjetas YA son la superficie: una card alrededor las anidaría.
    assert_selector("div.cards")
    assert_no_selector("div.card")
    assert_no_selector("div.overflow-x-auto")
  end

  def test_with_content_defaults_to_surface_and_accepts_surface_false
    render_inline(component) do |c|
      c.with_content { '<div class="custom-view"></div>'.html_safe }
    end
    assert_selector("div.card > div.card-body > div.custom-view")

    # Un contenido que trae su propio chrome (un calendario) apaga la superficie y NO pierde
    # el bloque en el camino.
    render_inline(component) do |c|
      c.with_content(surface: false) { '<div class="custom-view"></div>'.html_safe }
    end
    assert_selector("div.custom-view")
    assert_no_selector("div.card")
  end

  def test_the_toolbar_row_has_no_surface
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # La toolbar es la MISMA fila en todos los modos: bare, hija directa del componente.
    # La única card de la página es la del contenido, y los filtros quedan FUERA.
    assert_selector("div.data-table-component > div.flex.items-center div.filters")
    assert_no_selector("div.card div.filters")
    assert_no_selector("div.data-table-component > div.flex.items-center.bg-base-100")
  end

  def test_declaring_two_content_slots_raises
    # Dos declaraciones se pisaban en silencio y el host veía siempre la última: un modo
    # que no eligió. Ahora falla ruidoso y enseña el if sobre display_mode.
    error = assert_raises(Bali::DataTable::Component::DuplicateContent) do
      render_inline(component) do |c|
        c.with_table { '<div class="table-component"></div>'.html_safe }
        c.with_grid { '<div class="cards"></div>'.html_safe }
      end
    end
    assert_match(/with_table/, error.message)
  end

  def test_table_class_option_overrides_the_scroll_wrapper_classes
    @options = { table_class: "overflow-x-auto max-h-96" }
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("div.card-body > div.overflow-x-auto.max-h-96 > div.table-component")
  end

  def test_content_slot_forwards_card_options_to_the_surface
    render_inline(component) do |c|
      c.with_table(style: :bordered, class: "mt-2") { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("div.card.card-border.mt-2 div.table-component")
  end

  # --- View switch ---

  def declare_views(component_instance)
    component_instance.with_view_switch do |switch|
      switch.with_view(name: "Tabla", icon: "list", value: :table)
      switch.with_view(name: "Tarjetas", icon: "grid", value: :grid)
    end
  end

  def test_view_switch_renders_in_the_toolbar
    render_inline(component) do |c|
      declare_views(c)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # Sin nada más declarado la toolbar aparece igual: el switch la cuenta.
    assert_selector("div.data-table-component .view-switch-component a", count: 2)
    assert_selector("a[href*='view=table']")
    assert_selector("a[href*='view=grid']")
  end

  def test_unknown_view_param_falls_back_to_the_first_declared_view
    # Un `?view=` que nadie declaró no puede dejar el listado vacío: cae a la primera
    # vista, y el host lee ese valor ya validado para elegir su contenido.
    @options = { display_mode: :bogus }

    render_inline(component) do |c|
      declare_views(c)
      if c.display_mode == :grid
        c.with_grid { '<div class="cards"></div>'.html_safe }
      else
        c.with_table { '<div class="table-component"></div>'.html_safe }
      end
    end

    assert_selector("div.table-component")
    assert_no_selector("div.cards")
    assert_selector("a.btn-active[href*='view=table']")
  end

  def test_declared_view_drives_the_content_and_the_active_link
    @options = { display_mode: :grid }

    render_inline(component) do |c|
      declare_views(c)
      if c.display_mode == :grid
        c.with_grid { '<div class="cards"></div>'.html_safe }
      else
        c.with_table { '<div class="table-component"></div>'.html_safe }
      end
    end

    assert_selector("div.cards")
    assert_selector("a.btn-active[href*='view=grid']")
  end

  def test_view_param_option_renames_the_url_param
    @options = { view_param: :mode, display_mode: :grid }

    render_inline(component) do |c|
      declare_views(c)
      c.with_grid { '<div class="cards"></div>'.html_safe }
    end

    assert_selector("a[href*='mode=grid']")
    assert_no_selector("a[href*='view=']")
  end

  def test_display_mode_is_untouched_without_a_view_switch
    @options = { display_mode: :roadmap }
    assert_equal(:roadmap, component.display_mode)
  end

  def test_the_display_mode_falls_back_to_the_url_when_the_host_forgets_it
    # Un host que declara el switch y se olvida de `display_mode:` obtenía links que
    # cambiaban la URL y nunca la vista, en silencio: el componente ya tiene el query
    # string en la mano (arma esos mismos hrefs con él).
    with_request_url "/movies?view=grid" do
      render_inline(Bali::DataTable::Component.new(url: "/movies")) do |c|
        declare_views(c)
        assert_equal(:grid, c.display_mode)
        c.with_grid { '<div class="cards"></div>'.html_safe }
      end
    end

    assert_selector("a.btn-active[href*='view=grid']")
  end

  def test_the_view_taken_from_the_url_also_travels_as_a_hidden_field
    with_request_url "/movies?view=grid" do
      render_inline(Bali::DataTable::Component.new(url: "/movies")) do |c|
        c.with_filters_panel(available_attributes: filter_attributes)
        declare_views(c)
        c.with_grid { '<div class="cards"></div>'.html_safe }
      end
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
  end

  SavedViewsStore = Struct.new(:views) do
    def list = views
    def find(id) = views.find { |view| view.id.to_s == id.to_s }
  end

  def saved_views_form
    Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new, storage_id: "movies_index",
      saved_views_store: SavedViewsStore.new([])
    )
  end

  def test_the_saved_views_control_declares_its_priority_and_keeps_its_label
    # Vistas guardadas es el control cuya DUPLICACIÓN causó #669, y el único cuyo label es
    # dinámico (el nombre de la vista activa): dentro del ⋯ sin label queda un ícono anónimo.
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: saved_views_form)) do |c|
      c.with_saved_views
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="memory"]' \
                    '[data-toolbar-overflow-priority="30"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-priority="30"] span.toolbar-control-label', visible: :all)
    assert_selector('[data-controller~="saved-views"]', count: 1, visible: :all)
  end

  def test_a_declared_control_that_renders_nothing_does_not_open_the_overflow_menu
    # `with_saved_views` sobre un form sin store deja `render?` en false. Mirando el
    # predicado del slot quedaba un envoltorio VACÍO que el JS movía al ⋯, destapando un
    # botón que abre un menú en blanco.
    formless = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new)
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: formless)) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_saved_views
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector('[data-toolbar-overflow-priority="30"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_the_toolbar_emits_the_overflow_threshold_it_gated_with
    render_collapsible_toolbar

    assert_selector('[data-controller~="toolbar-overflow"]' \
                    "[data-toolbar-overflow-threshold-value=\"#{Bali::DataTable::Component::OVERFLOW_THRESHOLD}\"]",
                    visible: :all)
  end

  def test_the_overflow_menu_is_a_container_not_a_menu_of_menuitems
    # Adentro caen widgets enteros (dropdowns anidados, checkboxes, el form de renombrar):
    # `role="menu"` expone hijos que ese rol no permite.
    render_collapsible_toolbar

    assert_no_selector('[data-toolbar-overflow-target="overflow"] [role="menu"]', visible: :all)
    assert_selector('div[data-toolbar-overflow-target="menu"]', visible: :all)
  end

  def test_bulk_actions_puts_the_stimulus_controller_on_the_container
    render_inline(component) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector('div.data-table-component[data-controller~="bulk-actions"]')
  end

  def test_only_one_bulk_actions_controller_in_the_tree
    # Dos controladores anidados se reparten los targets y la barra deja de ver las filas,
    # en silencio: por eso el slot pide standalone: false.
    render_inline(component) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector('[data-controller~="bulk-actions"]', count: 1)
  end

  def test_bulk_actions_declares_each_action_exactly_once
    # El bloque del slot lo evalúa ViewComponent al leer `actions`. Correrlo también en el
    # lambda duplicaba cada acción sin fallar en ningún lado.
    render_inline(component) do |c|
      c.with_bulk_actions do |bulk|
        bulk.with_action(label: "Delete", href: "/delete")
        bulk.with_action(label: "Archive", href: "/archive")
      end
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector(".bulk-actions-component form", count: 2, visible: :all)
  end

  def test_container_has_no_bulk_actions_controller_without_the_slot
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector('[data-controller~="bulk-actions"]')
  end

  def test_bulk_actions_marks_the_toolbar_row_as_the_replaceable_node
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector('div.data-table-component > div[data-bulk-actions-target="toolbar"]')
  end

  def test_bulk_actions_bar_is_a_sibling_of_the_toolbar_and_not_nested_in_it
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component > div.bulk-actions-component")
    assert_no_selector('[data-bulk-actions-target="toolbar"] .bulk-actions-component')
  end

  def test_bulk_actions_alone_does_not_bring_up_the_toolbar_row
    # La barra contextual NO vive en la fila de la toolbar: sin otro control declarado no
    # hay toolbar que esconder.
    render_inline(component) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector('[data-bulk-actions-target="toolbar"]')
    assert_selector("div.bulk-actions-component")
  end

  # --- Toolbar overflow: el ⋯ de viewports angostos ---

  # Filtros (70, sobreviven) + columnas (35, colapsa): el caso mínimo con algo de cada lado
  # del umbral.
  def render_collapsible_toolbar
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  # Los tres grupos poblados: contenido de la vista (izquierda), cómo se recuerda (memory) y
  # cómo se ve (derecha). El form trae storage_id, así que el marcador de persistencia
  # también pinta. El view switch es lo ÚNICO que puebla la derecha desde que el export se
  # mudó al ⋯ del PageHeader.
  def render_full_toolbar
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: saved_views_form)) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_saved_views
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      declare_views(c)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  # El ColumnSelector no tiene test propio: su cobertura vive acá.
  # La aserción negativa VA scopeada al `data-controller`: el propio ⋯ de la toolbar se pinta
  # con `align: :bottom_end`, así que un `assert_no_selector('.dropdown-end')` pelado falla
  # contra un `dropdown-end` que es correcto y tiene que quedarse.
  def test_the_column_selector_popover_opens_to_the_left
    render_collapsible_toolbar

    assert_selector("[data-controller='column-selector'].dropdown", visible: :all)
    assert_no_selector("[data-controller='column-selector'].dropdown-end", visible: :all)
  end

  def test_toolbar_declares_the_overflow_controller_and_a_home_group_per_family
    render_full_toolbar

    assert_selector('div[data-controller~="toolbar-overflow"]', visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="left"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="memory"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="right"]',
                    count: 1, visible: :all)
    # Sin botones del host no hay grupo del host: un grupo vacío es un flex item que se lleva
    # el `gap` de la fila a los dos lados.
    assert_no_selector('[data-toolbar-overflow-group="host"]', visible: :all)
  end

  def test_the_left_group_reads_filters_then_group_by_then_columns
    # El JS reordena cada grupo por prioridad DESCENDENTE al expandir, así que el orden de la
    # fila lo fijan estos números y no el template: leídos de mayor a menor tienen que dar el
    # orden pedido.
    form = GroupableDataTableFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    priorities = page.all('[data-toolbar-overflow-group="left"][data-toolbar-overflow-target="item"]',
                          visible: :all).map { |item| item["data-toolbar-overflow-priority"].to_i }

    assert_equal [ 70, 40, 35 ], priorities
  end

  def test_the_memory_group_reads_saved_views_then_the_persistence_bookmark
    render_full_toolbar

    priorities = page.all('[data-toolbar-overflow-group="memory"][data-toolbar-overflow-target="item"]',
                          visible: :all).map { |item| item["data-toolbar-overflow-priority"].to_i }

    assert_equal [ 30, 25 ], priorities
  end

  def test_the_column_selector_collapses_from_the_left_group
    # Cambió de lado: era el subgrupo derecho ("cómo se ve") y ahora es contenido de la vista.
    render_full_toolbar

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="35"]', count: 1, visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="35"]',
                       visible: :all)
  end

  def test_the_separator_is_not_a_control
    # Marcada como `item` viajaría al ⋯ como si fuera un control, y con prioridad el JS la
    # reordenaría entre los controles del grupo. No es ninguna de las dos cosas.
    render_full_toolbar

    assert_selector('[data-toolbar-overflow-target="separator"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-separates="left memory"]', count: 1, visible: :all)
    assert_no_selector("[data-toolbar-overflow-separates][data-toolbar-overflow-priority]",
                       visible: :all)
    assert_no_selector('[data-toolbar-overflow-separates][data-toolbar-overflow-target~="item"]',
                       visible: :all)
    # Hermana de los dos grupos, no hija de ninguno: adentro de uno el JS la empuja al final.
    assert_no_selector('[data-toolbar-overflow-target="group"] [data-toolbar-overflow-target="separator"]',
                       visible: :all)
  end

  def test_the_separator_is_served_hidden_below_the_breakpoint
    # El caso sin JS: bajo `sm` no queda nadie a su derecha que la sostenga.
    render_full_toolbar

    assert_selector('[data-toolbar-overflow-target="separator"][class~="max-sm:hidden"]', visible: :all)
  end

  def test_no_separator_without_something_on_both_sides
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector('[data-toolbar-overflow-target="separator"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="memory"]', visible: :all)
  end

  def test_no_separator_with_only_the_memory_side
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: saved_views_form)) do |c|
      c.with_saved_views
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-group="memory"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="separator"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="left"]', visible: :all)
  end

  def test_only_the_view_switch_stays_on_the_right
    render_full_toolbar

    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="30"]',
                       visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="25"]',
                       visible: :all)
  end

  def test_host_buttons_get_their_own_group_and_leave_the_view_switch_pinned_right
    # Adentro del grupo derecho el JS los ordenaba por prioridad DESCENDENTE (10 contra 50) y
    # el botón del host terminaba a la derecha del view switch — que es lo único que puede ir
    # pegado al borde, porque es lo único que dice cómo se VE el listado.
    render_inline(component) do |c|
      declare_views(c)
      c.with_toolbar_button { '<button class="btn">Refresh</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="host"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-group="host"][data-toolbar-overflow-priority="10"]',
                    count: 1, visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="10"]',
                       visible: :all)
    assert_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="50"]',
                    count: 1, visible: :all)
  end

  def test_collapsible_controls_declare_their_priority_and_home_group
    render_collapsible_toolbar

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="70"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="35"]', count: 1, visible: :all)
  end

  def test_toolbar_controls_exist_exactly_once_in_the_dom
    # EL contrato del overflow: el JS MUEVE nodos. Sin este test, el patrón viejo
    # (`hidden md:block` + copia móvil) puede volver sin que nada falle — y dos copias del
    # selector de columnas son dos controladores manejando la misma tabla.
    render_collapsible_toolbar

    assert_selector('[data-toolbar-overflow-target="item"]', count: 2, visible: :all)
    assert_selector("div.filters", count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="menu"]', count: 1, visible: :all)
    # La zona de aterrizaje se sirve VACÍA: la llena el JS al colapsar.
    assert_no_selector('[data-toolbar-overflow-target="menu"] *', visible: :all)
  end

  def test_overflow_menu_is_served_hidden_and_revealed_by_the_javascript
    # Se sirve con `hidden` y lo destapa el JS al mover el primer control adentro: así no
    # parpadea un ⋯ que abre un menú vacío mientras el bundle carga.
    #
    # Sin `sm:hidden` a propósito: el colapso dejó de decidirlo el breakpoint y pasa a MEDIRSE
    # (`max-content` contra el ancho real de la fila), así que el ⋯ tiene que poder aparecer en
    # cualquier ancho — con un sidebar, una ventana de 1024px deja la toolbar sin lugar mucho
    # antes de llegar a `sm`. Una clase que lo escondiera arriba de 640px lo volvería
    # inalcanzable justo donde más falta hace.
    render_collapsible_toolbar

    assert_selector('[data-toolbar-overflow-target="overflow"][class~="hidden"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="overflow"][class~="sm:hidden"]', visible: :all)
  end

  def test_collapsible_controls_mark_their_label_for_the_overflow_menu
    # Contrato con data_table/index.css: los controles esconden su label bajo `sm` para no
    # comerse la fila, y adentro del ⋯ —donde sobra ancho— vuelve. Sin las dos clases el
    # menú queda con iconos anónimos, y eso ningún test de CSS lo ve.
    form = GroupableDataTableFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="menu"].toolbar-overflow-menu', visible: :all)
    assert_selector('[data-toolbar-overflow-priority="35"] span.toolbar-control-label',
                    text: "Columns", visible: :all)
    assert_selector('[data-toolbar-overflow-priority="40"] span.toolbar-control-label',
                    text: "Group by", visible: :all)
  end

  def test_overflow_menu_is_not_rendered_without_collapsible_controls
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="menu"]', visible: :all)
  end

  def test_view_switch_does_not_open_the_overflow_menu_by_itself
    # Prioridad 50 = umbral: el switch se ENCOGE (icon_only responsive), no se colapsa. Si
    # abriera el ⋯ siendo lo único extra declarado, el menú saldría vacío.
    render_inline(component) do |c|
      declare_views(c)
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-priority="50"]',
                    count: 1, visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_view_switch_collapses_its_labels_below_the_breakpoint
    render_inline(component) do |c|
      declare_views(c)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # El label se colapsa por CSS, pero el nombre accesible viaja siempre: en móvil el
    # botón queda con solo un icono.
    assert_selector("a[title='Tabla'][aria-label='Tabla']")
    assert_selector("a[href*='view=table'] span[class~='max-sm:hidden']", text: "Tabla")
  end

  def test_group_by_control_collapses_from_the_left_group
    form = GroupableDataTableFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel
      c.with_table { "".html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="40"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-priority="40"] span.toolbar-control-label', visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_each_toolbar_button_gets_its_own_collapsible_wrapper
    render_inline(component) do |c|
      c.with_toolbar_button { '<button class="btn">A</button>'.html_safe }
      c.with_toolbar_button { '<button class="btn">B</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="host"]' \
                    '[data-toolbar-overflow-priority="10"]', count: 2, visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_toolbar_row_keeps_the_overflow_controller_and_the_bulk_actions_target
    # Los dos viven en la MISMA fila: la barra contextual la esconde entera, el overflow
    # reacomoda lo que hay adentro. Escribir el hash `data` en vez de mergearlo borraba el
    # controlador sin fallar en ningún lado.
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('div[data-controller~="toolbar-overflow"][data-bulk-actions-target="toolbar"]',
                    visible: :all)
  end

  def test_filters_panel_preserves_the_declared_display_mode_as_hidden_field
    # El submit de filtros reconstruye la URL desde `url:`, que el host pasa SIN query
    # string: sin este hidden, filtrar estando en tarjetas devolvía al usuario a la tabla.
    @options = { display_mode: :grid }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
  end

  def test_simple_filters_preserve_the_declared_display_mode_as_hidden_field
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form,
                                                 display_mode: :grid)) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_no_view_hidden_field_when_the_host_declares_no_display_mode
    # Un listado sin view switch no tiene por qué escribir `view=table` en la URL.
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector("input[type=hidden][name=view]", visible: :all)
  end

  def test_the_preserved_view_field_follows_view_param
    @options = { display_mode: :grid, view_param: :mode }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=mode][value=grid]", visible: :all)
    assert_no_selector("input[type=hidden][name=view]", visible: :all)
  end

  def test_explicit_preserved_params_do_not_drop_the_active_view
    @options = { display_mode: :grid }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes, preserved_params: { tab: "archived" })
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
    assert_selector("form input[type=hidden][name=tab][value=archived]", visible: :all)
  end

  def test_a_nested_view_param_does_not_blow_up_the_component
    # `display_mode:` suele llegar directo de params[:view]; `?view[]=x` no responde a
    # to_sym y reventaba el render entero antes de llegar al gateo.
    @options = { display_mode: [ "grid" ] }
    render_inline(component) do |c|
      c.with_view_switch { |vs| vs.with_view(name: "Table", icon: "list", value: :table) }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("div.data-table-component")
    assert_selector('.view-switch-component a[aria-current="page"]', text: "Table")
  end

  def test_actions_panel_is_gone
    # El panel entero murió: su toggle grid/tabla lo reemplaza with_view_switch, su export
    # el ⋯ del PageHeader (page.with_export) y su hueco de acciones with_bulk_actions.
    # Romper ruidoso > seguir pintando el camino de #653.
    refute_respond_to(component, :with_actions_panel)
    refute(Bali::DataTable.const_defined?(:ActionsPanel))
  end

  def test_export_is_not_a_toolbar_slot
    # El export se mudó al ⋯ del PageHeader (`page.with_export`): exportar es una acción
    # SOBRE la página, no un control de cómo se ve el listado. `dt.with_export` tiene que
    # levantar NoMethodError y no seguir pintando un botón que ignora los filtros.
    refute_respond_to(component, :with_export)
    refute(Bali::DataTable::Component::OVERFLOW_PRIORITIES.key?(:export))
  end

  # --- footer ---------------------------------------------------------------------------
  #
  # El footer ya no se dibuja acá: es el MISMO PaginationFooter que cualquier host puede
  # renderizar suelto. Lo que estos tests fijan es que el listado siga produciendo el
  # summary y los controles, y que los siga produciendo UNA sola vez.

  def render_with_pagy(pagy, **options)
    @options = options.merge(pagy: pagy)
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
      yield c if block_given?
    end
  end

  def test_footer_renders_the_summary_and_the_controls
    render_with_pagy(Pagy::Offset.new(count: 47, page: 2, limit: 10), item_name: "movies")

    assert_text("Showing 11-20 of 47 movies")
    assert_selector("nav.pagy-nav-daisyui .join")
  end

  def test_footer_summary_is_emitted_once
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10), item_name: "movies")

    assert_equal 1, page.text.scan("Showing 1-10 of 47 movies").size
  end

  # Test de caracterización: la lista LITERAL de clases que el footer del listado tenía en 3.0,
  # cuando se dibujaba inline acá. Mover el footer a PaginationFooter no puede cambiar un pixel
  # del pie de la tabla, y la primera versión de ese cambio sí lo movió: el `py-4` del footer
  # suelto se sumaba al `pt-4` del listado y metía 16px de padding inferior donde no había
  # ninguno. Si esta cadena cambia, cámbiala a propósito y documéntalo.
  FOOTER_CLASSES_ON_3_0 =
    "flex flex-col sm:flex-row items-center justify-between gap-4 mt-4 pt-4 border-t border-base-200"

  def test_footer_keeps_the_exact_box_it_had_when_it_was_inline
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10), item_name: "movies")

    footer = page.find("div.data-table-component > div:last-child")
    assert_equal FOOTER_CLASSES_ON_3_0.split.sort, footer[:class].split.sort
  end

  def test_footer_falls_back_to_the_shared_item_name
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10))

    assert_text("Showing 1-10 of 47 items")
  end

  # Con cero resultados el listado decía "Showing 0-0 of 0 movies" debajo de una tabla vacía.
  def test_footer_says_nothing_without_results
    render_with_pagy(Pagy::Offset.new(count: 0, page: 1, limit: 10), item_name: "movies")

    assert_no_text("Showing")
    assert_no_selector(".border-t")
  end

  def test_top_summary_says_nothing_without_results
    render_with_pagy(Pagy::Offset.new(count: 0, page: 1, limit: 10),
      item_name: "movies", summary_position: :top)

    assert_no_text("Showing")
  end

  def test_top_summary_replaces_the_footer_one
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10),
      item_name: "movies", summary_position: :top)

    assert_equal 1, page.text.scan("Showing 1-10 of 47 movies").size
  end

  def test_custom_pagy_nav_replaces_the_controls
    render_with_pagy(Pagy::Offset.new(count: 47, page: 2, limit: 10)) do |c|
      c.with_custom_pagy_nav { '<nav class="my-nav"></nav>'.html_safe }
    end

    assert_selector("nav.my-nav")
    assert_no_selector("nav.pagy-nav-daisyui")
    assert_text("Showing 11-20 of 47 items")
  end

  def test_no_footer_without_a_pagy
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector(".border-t")
    assert_no_text("Showing")
  end
end
