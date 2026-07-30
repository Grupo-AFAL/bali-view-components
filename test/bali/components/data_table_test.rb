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

  def grouping_filter_form(group_by: "genre")
    Bali::FilterForm.new(
      Movie.all,
      ActionController::Parameters.new(q: ActionController::Parameters.new({}), group_by: group_by),
      simple_filters: [ { attribute: :genre, collection: [ %w[Action Action] ], blank: "All" } ],
      group_by_attributes: %i[genre status]
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

    # Un contenido que trae su propio chrome (un Gantt) apaga la superficie y NO pierde
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
    @options = { display_mode: :gantt }
    assert_equal(:gantt, component.display_mode)
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

  # Filtros (70, sobreviven) + export (10, colapsa): el caso mínimo con algo de cada lado
  # del umbral.
  def render_toolbar_with_export
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_export(formats: [ :csv ], url: "/movies")
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  def test_toolbar_declares_the_overflow_controller_and_both_home_groups
    render_toolbar_with_export

    assert_selector('div[data-controller~="toolbar-overflow"]', visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="left"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="right"]',
                    count: 1, visible: :all)
  end

  def test_collapsible_controls_declare_their_priority_and_home_group
    render_toolbar_with_export

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="70"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="right"]' \
                    '[data-toolbar-overflow-priority="10"]', count: 1, visible: :all)
  end

  def test_toolbar_controls_exist_exactly_once_in_the_dom
    # EL contrato del overflow: el JS MUEVE nodos. Sin este test, el patrón viejo
    # (`hidden md:block` + copia móvil) puede volver sin que nada falle — y dos copias del
    # selector de columnas son dos controladores manejando la misma tabla.
    render_toolbar_with_export

    assert_selector('[data-toolbar-overflow-target="item"]', count: 2, visible: :all)
    assert_selector("div.filters", count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="menu"]', count: 1, visible: :all)
    # La zona de aterrizaje se sirve VACÍA: la llena el JS al colapsar.
    assert_no_selector('[data-toolbar-overflow-target="menu"] *', visible: :all)
  end

  def test_overflow_menu_is_served_hidden_and_only_visible_below_the_breakpoint
    # Se sirve con `hidden` y lo destapa el JS al mover el primer control adentro: así no
    # parpadea un ⋯ que abre un menú vacío mientras el bundle carga.
    render_toolbar_with_export

    assert_selector('[data-toolbar-overflow-target="overflow"][class~="hidden"]', visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"][class~="sm:hidden"]', visible: :all)
  end

  def test_collapsible_controls_mark_their_label_for_the_overflow_menu
    # Contrato con data_table/index.css: los controles esconden su label bajo `sm` para no
    # comerse la fila, y adentro del ⋯ —donde sobra ancho— vuelve. Sin las dos clases el
    # menú queda con iconos anónimos, y eso ningún test de CSS lo ve.
    render_inline(component) do |c|
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_export(formats: [ :csv ], url: "/movies")
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="menu"].toolbar-overflow-menu', visible: :all)
    assert_selector('[data-toolbar-overflow-priority="20"] span.toolbar-control-label',
                    text: "Columns", visible: :all)
    assert_selector('[data-toolbar-overflow-priority="10"] span.toolbar-control-label',
                    text: "Export", visible: :all)
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
                    '[data-toolbar-overflow-priority="30"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-priority="30"] span.toolbar-control-label', visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_each_toolbar_button_gets_its_own_collapsible_wrapper
    render_inline(component) do |c|
      c.with_toolbar_button { '<button class="btn">A</button>'.html_safe }
      c.with_toolbar_button { '<button class="btn">B</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="right"]' \
                    '[data-toolbar-overflow-priority="10"]', count: 2, visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_toolbar_row_keeps_the_overflow_controller_and_the_bulk_actions_target
    # Los dos viven en la MISMA fila: la barra contextual la esconde entera, el overflow
    # reacomoda lo que hay adentro. Escribir el hash `data` en vez de mergearlo borraba el
    # controlador sin fallar en ningún lado.
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_export(formats: [ :csv ], url: "/movies")
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('div[data-controller~="toolbar-overflow"][data-bulk-actions-target="toolbar"]',
                    visible: :all)
  end

  def test_actions_panel_is_gone
    # El panel entero murió: su toggle grid/tabla lo reemplaza with_view_switch, su export
    # with_export y su hueco de acciones with_bulk_actions. Romper ruidoso > seguir
    # pintando el camino de #653.
    refute_respond_to(component, :with_actions_panel)
    refute(Bali::DataTable.const_defined?(:ActionsPanel))
  end
end
