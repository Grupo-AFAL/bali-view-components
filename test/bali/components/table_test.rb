# frozen_string_literal: true

require "test_helper"

class BaliTableComponentTest < ComponentTestCase
  def setup
    @options = {}
    @filter_form = Struct.new(:active_filters?, :id).new(false, "filter-form-1")
  end

  def component
    Bali::Table::Component.new(**@options)
  end

  def test_constants_defines_table_classes
    assert_equal("table table-zebra min-w-full", Bali::Table::Component::TABLE_CLASSES)
  end

  def test_constants_defines_container_classes
    assert_equal("overflow-x-auto table-component", Bali::Table::Component::CONTAINER_CLASSES)
  end

  def test_constants_defines_sticky_classes
    assert_includes(Bali::Table::Component::STICKY_CLASSES, "overflow-visible")
  end

  def test_headers_renders_a_table_with_headers_using_array_syntax
    render_inline(component) do |c|
      c.with_headers([
      { name: "name" }, { name: "amount" }
      ])
    end
    assert_selector("table")
    assert_selector("tr th", text: "name")
    assert_selector("tr th", text: "amount")
  end

  def test_headers_renders_a_table_with_headers_using_singular_syntax
    render_inline(component) do |c|
      c.with_header(name: "name")
      c.with_header(name: "amount", class: "text-right")
    end
    assert_selector("table")
    assert_selector("tr th.whitespace-nowrap", text: "name")
    assert_selector("tr th.text-right", text: "amount")
  end

  def test_headers_excludes_hidden_headers_from_rendering
    render_inline(component) do |c|
      c.with_header(name: "visible")
      c.with_header(name: "hidden", hidden: true)
    end
    assert_selector("tr th", text: "visible")
    assert_no_selector("tr th", text: "hidden")
  end

  # --- Sort affordance (Bali::Table::Header) ---

  # `sort_link` arma el href con `url_for`, así que necesita una request ENRUTABLE: en el
  # contexto pelado de un component test no hay controller ni action y levanta
  # UrlGenerationError antes de renderear nada. Mismo patrón que data_table_test.rb:420 y
  # view_switch_test.rb:64 — cualquier test que renderee un header ordenable pasa por acá.
  def render_sortable_table(sort: nil, &block)
    params = sort ? { q: { s: sort } } : {}
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(params))
    with_request_url("/admin/movies") do
      render_inline(Bali::Table::Component.new(form: form), &block)
    end
  end

  def test_headers_marks_a_sortable_column_that_is_not_sorted_yet
    render_sortable_table do |c|
      c.with_header(name: "Name", sort: :name)
    end
    assert_selector("th[aria-sort='none'] a.sort_link svg")
  end

  # Ransack solo pintaba flecha en la columna ORDENADA (`default_arrow` es nil): una columna
  # ordenable se veía idéntica a una que no lo es. Esta es la aserción que lo fija.
  def test_headers_do_not_render_ransacks_text_arrow
    render_sortable_table(sort: "name desc") do |c|
      c.with_header(name: "Name", sort: :name)
    end
    assert_no_text("▼")
    assert_no_text("▲")
  end

  def test_headers_announce_the_active_sort_direction_on_the_th
    render_sortable_table(sort: "name desc") do |c|
      c.with_header(name: "Name", sort: :name)
      c.with_header(name: "Amount", sort: :budget)
    end
    assert_selector("th[aria-sort='descending']", text: "Name")
    assert_selector("th[aria-sort='none']", text: "Amount")
  end

  def test_headers_announce_an_ascending_sort
    render_sortable_table(sort: "name asc") do |c|
      c.with_header(name: "Name", sort: :name)
    end
    assert_selector("th[aria-sort='ascending']", text: "Name")
  end

  def test_headers_without_sort_carry_no_sort_semantics
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_no_selector("th[aria-sort]")
    assert_no_selector("th svg")
  end

  # El estado lo anuncia `aria-sort` una sola vez: el ícono es decoración.
  def test_headers_hide_the_sort_indicator_from_assistive_tech
    render_sortable_table do |c|
      c.with_header(name: "Name", sort: :name)
    end
    assert_selector("th a.sort_link span[aria-hidden='true']")
  end

  # `sort_link` mergea al HREF toda opción que no sea class/data (`title:` sale como
  # `&title=...`): si alguien "mejora" el link con una opción nueva, esto lo caza.
  def test_headers_sort_links_carry_only_the_sort_param
    render_sortable_table do |c|
      c.with_header(name: "Name", sort: :name)
    end
    href = page.find("th a.sort_link")[:href]
    assert_equal({ "q" => { "s" => "name asc" } }, Rack::Utils.parse_nested_query(href.split("?").last))
  end

  def test_headers_raise_without_a_filter_form_when_sorting_is_requested
    assert_raises(Bali::Table::Component::MissingFilterForm) do
      render_inline(component) { |c| c.with_header(name: "Name", sort: :name) }
    end
  end

  def test_rows_renders_a_table_with_rows
    render_inline(component) do |c|
      c.with_row { "<td>Hola</td>".html_safe }
    end
    assert_selector("tr td", text: "Hola")
  end

  def test_footer_renders_a_table_with_footer
    render_inline(component) do |c|
      c.with_footer { "<td>Total</td>".html_safe }
    end
    assert_selector("table")
    assert_selector("tfoot tr td", text: "Total")
  end

  def test_empty_states_renders_no_results_message_when_filters_are_active
    active_form = Struct.new(:active_filters?, :id).new(true, "1")
    @options = { form: active_form }
    render_inline(component)
    assert_selector(".empty-table p", text: "No Results")
  end

  def test_empty_states_renders_no_records_message_when_no_filters
    @options = { form: @filter_form }
    render_inline(component)
    assert_selector(".empty-table p", text: "No Records")
  end

  def test_empty_states_renders_a_table_with_new_record_link
    render_inline(component) do |c|
      c.with_new_record_link(name: "Add New Record", href: "#", modal: false)
    end
    assert_selector("a", text: "Add New Record")
  end

  def test_empty_states_with_custom_no_records_notification_renders_custom_message
    @options = { form: @filter_form }
    render_inline(component) do |c|
      c.with_no_records_notification { "So sorry, no records found!" }
    end
    assert_selector(".empty-table", text: "So sorry, no records found!")
  end

  def test_empty_states_with_custom_no_results_notification_renders_custom_message_when_filters_active
    active_form = Struct.new(:active_filters?, :id).new(true, "1")
    @options = { form: active_form }
    render_inline(component) do |c|
      c.with_no_results_notification { "So sorry, no results!" }
    end
    assert_selector(".empty-table", text: "So sorry, no results!")
  end

  def test_empty_states_default_renders_through_empty_state_component
    @options = { form: @filter_form }
    render_inline(component)
    assert_selector(".empty-table .empty-state-component p", text: "No Records")
  end

  def test_empty_states_new_record_link_renders_inside_the_empty_state_cta
    render_inline(component) do |c|
      c.with_new_record_link(name: "Add New Record", href: "#", modal: false)
    end
    assert_selector(".empty-table .empty-state-component a", text: "Add New Record")
  end

  def test_empty_states_new_record_link_is_hidden_when_filters_are_active
    active_form = Struct.new(:active_filters?, :id).new(true, "1")
    @options = { form: active_form }
    render_inline(component) do |c|
      c.with_new_record_link(name: "Add New Record", href: "#", modal: false)
    end
    assert_no_selector(".empty-table a", text: "Add New Record")
  end

  def test_empty_states_custom_notification_sits_in_the_shared_empty_state_container
    @options = { form: @filter_form }
    render_inline(component) do |c|
      c.with_no_records_notification { "So sorry, no records found!" }
    end
    assert_selector(".empty-table div.empty-state-component.py-8", text: "So sorry, no records found!")
  end

  # `bulk_actions:` caería en `**options` y saldría como atributo del `<table>`: la tabla se
  # vería bien, sin columna de checkbox y sin barra. El guardia existe para que reviente.
  def test_the_removed_bulk_actions_option_raises_instead_of_becoming_an_html_attribute
    error = assert_raises(ArgumentError) do
      Bali::Table::Component.new(bulk_actions: [ { name: "Delete", href: "/delete" } ])
    end
    assert_match("selectable: true", error.message)
  end

  def test_the_removed_bulk_actions_option_raises_on_a_row_too
    assert_raises(ArgumentError) do
      Bali::Table::Row::Component.new(record_id: 1, bulk_actions: true)
    end
  end

  def test_a_plain_table_carries_no_stimulus_controller
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row { "<td>Row 1</td>".html_safe }
    end
    assert_no_selector("[data-controller]")
    assert_no_selector('input[type="checkbox"]')
  end

  def test_selectable_renders_the_select_all_header
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
    end
    assert_selector('th input[data-bulk-actions-target="selectAll"][data-action*="bulk-actions#toggleAll"]')
  end

  def test_selectable_marks_each_row_as_a_bulk_actions_item
    # El `<tr>` ES el item: lleva el record id y la clase `selected`. El checkbox de la
    # celda solo dispara la acción.
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
    end
    assert_selector('tr[data-bulk-actions-target="item"][data-record-id="1"] td input[type="checkbox"][value="1"]')
    assert_selector('tr[data-record-id="1"] td input[data-action="change->bulk-actions#toggleItem"]')
  end

  def test_the_empty_state_spans_the_selection_column_too
    # `headers.count` ignoraba la columna de checkbox: el empty state quedaba una columna
    # corto y descentrado en cada listado filtrado a cero.
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "A")
      c.with_header(name: "B")
    end

    assert_selector("thead th", count: 3)
    assert_selector("td.empty-table[colspan='3']")
  end

  def test_the_empty_state_ignores_hidden_headers
    render_inline(component) do |c|
      c.with_header(name: "A")
      c.with_header(name: "B", hidden: true)
    end

    assert_selector("thead th", count: 1)
    assert_selector("td.empty-table[colspan='1']")
  end

  def test_select_label_names_the_row_checkbox_after_its_record
    # Sin él, N filas dan N controles con el MISMO nombre accesible y en el rotor de
    # formularios del lector de pantalla son indistinguibles.
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, select_label: "Blade Runner") { "<td>Row 1</td>".html_safe }
      c.with_row(record_id: 2) { "<td>Row 2</td>".html_safe }
    end

    assert_selector('tr[data-record-id="1"] input[aria-label="Select Blade Runner"]')
    assert_selector('tr[data-record-id="2"] input[aria-label="Select row"]')
  end

  def test_selectable_requires_record_id_on_each_row
    @options = { selectable: true }
    assert_raises(Bali::Table::Row::Component::IncompatibleOptions) do
      render_inline(component) do |c|
        c.with_header(name: "Name")
        c.with_row { "<td>Row 1</td>".html_safe }
      end
    end
  end

  def test_selectable_row_data_merges_with_host_data_attributes
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 7, data: { turbo_frame: "movie_7" }) { "<td>Row</td>".html_safe }
    end
    assert_selector('tr[data-record-id="7"][data-turbo-frame="movie_7"][data-bulk-actions-target="item"]')
  end

  # El controlador `table` se borró en v3: la selección la conduce `bulk-actions` desde un
  # ancestro. Un target huérfano acá sería un checkbox que no dispara nada.
  def test_selectable_does_not_render_the_legacy_table_targets
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
    end
    assert_no_selector('[data-table-target="toggleAll"]')
    assert_no_selector('[data-table-target="checkbox"]')
    assert_no_selector('[data-controller~="table"]')
  end

  def test_selectable_returns_false_by_default
    refute(Bali::Table::Component.new.selectable?)
  end

  # ---------------------------------------------------------------------------
  # Selección por subgrupo (#1047)
  # ---------------------------------------------------------------------------

  # Sin `select_group:` el markup sale como salía: un seleccionar-todo sin grupo alcanza a
  # TODA la selección del controlador, que con una sola tabla es lo mismo de siempre.
  def test_selection_groups_are_absent_unless_asked_for
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
    end
    assert_no_selector("[data-bulk-actions-group]")
  end

  def test_select_group_scopes_the_header_checkbox_and_stamps_every_row
    @options = { selectable: true, select_group: "depto-42" }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
      c.with_row(record_id: 2) { "<td>Row 2</td>".html_safe }
    end

    assert_selector('th input[data-bulk-actions-target="selectAll"][data-bulk-actions-group="depto-42"]')
    assert_selector('tr[data-record-id="1"][data-bulk-actions-group="depto-42"]')
    assert_selector('tr[data-record-id="2"][data-bulk-actions-group="depto-42"]')
  end

  def test_grouped_rows_get_their_own_select_all_scoped_to_the_group
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(record_id: 2, group: "Sur") { "<td>B</td>".html_safe }
    end

    norte = Bali::Table::Component.new(selectable: true).group_token("Norte")
    sur = Bali::Table::Component.new(selectable: true).group_token("Sur")

    refute_equal(norte, sur)
    assert_selector("tr.bali-table-group-row " \
                    "input[data-bulk-actions-target='selectAll'][data-bulk-actions-group='#{norte}']")
    assert_selector("tr[data-record-id='1'][data-bulk-actions-group='#{norte}']")
    assert_selector("tr[data-record-id='2'][data-bulk-actions-group='#{sur}']")
  end

  # Los dos ids a la vez, separados por espacio como las clases: la cabecera de la tabla
  # marca las 3 filas, el encabezado de cada grupo solo las suyas.
  def test_a_row_carries_both_the_table_group_and_its_own_group
    @options = { selectable: true, select_group: "depto-42" }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
    end

    table = Bali::Table::Component.new(selectable: true, select_group: "depto-42")
    assert_selector("tr[data-record-id='1']" \
                    "[data-bulk-actions-group='depto-42 #{table.group_token('Norte')}']")
  end

  # Un valor de grupo que reaparece más abajo es EL MISMO grupo: su seleccionar-todo marca
  # las dos corridas, que es lo que dice su etiqueta.
  def test_the_same_group_value_shares_one_token_across_runs
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(record_id: 2, group: "Sur") { "<td>B</td>".html_safe }
      c.with_row(record_id: 3, group: "Norte") { "<td>C</td>".html_safe }
    end

    norte = Bali::Table::Component.new(selectable: true).group_token("Norte")
    assert_selector("tr[data-bulk-actions-group='#{norte}']", count: 2)
    assert_selector("input[data-bulk-actions-group='#{norte}']", count: 2)
  end

  def test_the_group_select_all_is_named_after_its_group
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(record_id: 2, group: nil) { "<td>B</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row input[aria-label='Select all in Norte']")
    assert_selector("tr.bali-table-group-row input[aria-label='Select all in Ungrouped']")
  end

  # Una casilla que no marcaría nada es un control muerto: la celda se pinta igual, para
  # sostener la alineación, pero vacía.
  def test_a_group_with_no_selectable_rows_gets_no_select_all
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(selectable: false, group: "Retirados") { "<td>B</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row", count: 2)
    assert_selector("tr.bali-table-group-row input", count: 1)
    assert_selector("tr.bali-table-group-row td", count: 4)
  end

  # El acento de la izquierda se muda a la celda de la casilla, que pasa a ser la primera.
  def test_the_group_header_keeps_its_accent_on_the_leftmost_cell
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td.w-4.border-l-4.border-l-primary")
    assert_no_selector("tr.bali-table-group-row td[colspan].border-l-4")
  end

  def test_a_table_without_selection_keeps_the_single_group_header_cell
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", count: 1)
    assert_selector("tr.bali-table-group-row td.border-l-4.border-l-primary", text: "Norte (1)")
    assert_no_selector("tr.bali-table-group-row input")
  end

  # ---------------------------------------------------------------------------
  # Filas fuera de la selección (#1047)
  # ---------------------------------------------------------------------------

  def test_a_row_can_opt_out_of_the_selection
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
      c.with_row(selectable: false) { "<td>Row 2</td>".html_safe }
    end

    assert_selector('tr[data-bulk-actions-target="item"]', count: 1)
    assert_selector('tbody tr input[type="checkbox"]', count: 1)
  end

  # La celda se pinta vacía: sin ella las columnas de esa fila se corren una posición.
  def test_a_non_selectable_row_keeps_the_column_alignment
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_header(name: "Amount")
      c.with_row(record_id: 1) { "<td>A</td><td>1</td>".html_safe }
      c.with_row(selectable: false) { "<td>B</td><td>2</td>".html_safe }
    end

    assert_selector("tbody tr", count: 2)
    page.all("tbody tr").each { |row| assert_equal(3, row.all("td").count) }
  end

  def test_a_non_selectable_row_needs_no_record_id
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(selectable: false) { "<td>Row</td>".html_safe }
    end

    assert_selector("tbody tr td", text: "Row")
  end

  # `skip_tr` y la selección se siguen peleando —la fila no puede llevar el record id si no
  # hay `<tr>` que la lleve—, pero una fila que se declaró fuera de la selección ya no.
  def test_skip_tr_is_allowed_on_a_row_that_left_the_selection
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>A</td>".html_safe }
      c.with_row(selectable: false, skip_tr: true) do
        "<tr class='mine'><td>B</td></tr>".html_safe
      end
    end

    assert_selector("tr.mine td", text: "B")
  end

  # Solo se puede salir de la selección, no entrar: la columna y el seleccionar-todo los
  # pinta la TABLA, así que una fila seleccionable ahí adentro sería una casilla suelta con
  # las columnas corridas una posición.
  def test_a_row_cannot_opt_into_selection_on_a_plain_table
    error = assert_raises(ArgumentError) do
      render_inline(component) do |c|
        c.with_header(name: "Name")
        c.with_row(selectable: true, record_id: 9) { "<td>A</td>".html_safe }
      end
    end

    assert_match(/selectable: true/, error.message)
  end

  def test_sticky_headers_applies_sticky_classes_when_enabled
    @options = { sticky_headers: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_selector(".overflow-visible")
  end

  def test_sticky_headers_does_not_apply_sticky_classes_by_default
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_no_selector(".overflow-visible")
  end

  def test_daisyui_classes_applies_table_and_table_zebra_classes
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_selector("table.table.table-zebra")
  end

  def test_daisyui_classes_wraps_table_in_container_with_overflow_classes
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_selector(".overflow-x-auto.table-component")
  end

  def test_options_passthrough_accepts_custom_id
    @options = { id: "my-table" }
    render_inline(component)
    assert_selector("#my-table")
  end

  def test_options_passthrough_accepts_custom_classes
    @options = { class: "custom-class" }
    render_inline(component)
    assert_selector("table.custom-class")
  end

  def test_options_passthrough_accepts_tbody_options
    @options = { tbody: { class: "custom-tbody" } }
    render_inline(component)
    assert_selector("tbody.custom-tbody")
  end

  def test_options_passthrough_accepts_table_container_options
    @options = { table_container: { class: "custom-container" } }
    render_inline(component)
    assert_selector("div.custom-container")
  end

  def test_container_id_returns_custom_id_when_provided
    c = Bali::Table::Component.new(id: "custom-id")
    assert_equal("custom-id", c.container_id)
  end

  def test_container_id_returns_form_id_when_no_custom_id
    form = Struct.new(:id).new("form-123")
    c = Bali::Table::Component.new(form: form)
    assert_equal("form-123", c.container_id)
  end

  def test_container_id_returns_nil_when_no_id_or_form
    c = Bali::Table::Component.new
    assert_nil(c.container_id)
  end

  def test_selectable_predicate_follows_the_option
    assert(Bali::Table::Component.new(selectable: true).selectable?)
    refute(Bali::Table::Component.new.selectable?)
  end

  def test_grouping_emits_header_row_when_group_value_changes
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte") { "<td>B</td>".html_safe }
      c.with_row(group: "Sur") { "<td>C</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row", count: 2)
    assert_selector("tr.bali-table-group-row td", text: "Norte (2)")
    assert_selector("tr.bali-table-group-row td", text: "Sur (1)")
  end

  def test_grouping_counts_only_consecutive_rows_sharing_the_value
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Sur") { "<td>B</td>".html_safe }
      c.with_row(group: "Norte") { "<td>C</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row", count: 3)
    assert_selector("tr.bali-table-group-row td", text: "Norte (1)", count: 2)
    assert_selector("tr.bali-table-group-row td", text: "Sur (1)")
  end

  def test_grouping_header_colspan_matches_visible_headers_without_a_selection_column
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_header(name: "Amount")
      c.with_header(name: "Hidden", hidden: true)
      c.with_row(group: "Norte") { "<td>A</td><td>1</td>".html_safe }
    end
    assert_selector('tr.bali-table-group-row td[colspan="2"]')
  end

  # Con selección, la columna de casillas se la queda el seleccionar-todo del grupo: la
  # etiqueta cubre el resto y entre las dos celdas la fila sigue midiendo lo mismo.
  def test_grouping_header_splits_the_selection_column_off_the_label
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_header(name: "Amount")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td><td>1</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", count: 2)
    assert_selector('tr.bali-table-group-row td.w-4 input[type="checkbox"]')
    assert_selector('tr.bali-table-group-row td[colspan="2"]', text: "Norte (1)")
  end

  def test_grouping_renders_no_header_rows_when_no_group_given
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row { "<td>A</td>".html_safe }
      c.with_row { "<td>B</td>".html_safe }
    end
    assert_no_selector("tr.bali-table-group-row")
    assert_selector("tbody tr td", text: "A")
    assert_selector("tbody tr td", text: "B")
  end

  def test_grouping_does_not_leak_group_as_html_attribute
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end
    assert_no_selector("tr[group]")
  end

  def test_grouping_labels_nil_group_with_i18n_fallback
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: nil) { "<td>B</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", text: "Norte (1)")
    assert_selector("tr.bali-table-group-row td", text: "Ungrouped (1)")
  end

  def test_grouping_escapes_html_in_group_value
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "<script>alert('x')</script>") { "<td>A</td>".html_safe }
    end
    refute_includes(page.native.to_html, "<script>alert('x')</script>")
    assert_selector("tr.bali-table-group-row td", text: "<script>alert('x')</script> (1)")
  end

  def test_grouping_shows_global_count_when_group_counts_given
    @options = { group_counts: { "Norte" => 30 } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", text: "Norte (30)")
  end

  def test_grouping_appends_partial_hint_when_run_smaller_than_global_total
    @options = { group_counts: { "Norte" => 30 } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte") { "<td>B</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", text: "Norte (30) — showing 2")
  end

  def test_grouping_omits_partial_hint_when_run_matches_global_total
    @options = { group_counts: { "Norte" => 2 } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte") { "<td>B</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", text: "Norte (2)")
    assert_no_selector("tr.bali-table-group-row td", text: "showing")
  end

  def test_grouping_tolerant_lookup_matches_string_key_for_symbol_group_value
    @options = { group_counts: { "active" => 9 } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: :active) { "<td>A</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", text: "active (9)")
  end

  def test_grouping_falls_back_to_local_count_on_missing_global_key
    @options = { group_counts: { "Norte" => 30 } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Sur") { "<td>A</td>".html_safe }
    end
    # "Sur" is not in group_counts → page-local count (1), no crash
    assert_selector("tr.bali-table-group-row td", text: "Sur (1)")
  end

  # #1086 — la banda rotulaba con el valor de la base (`table`, `view`), y traducirlo por el
  # camino obvio —pasar la etiqueta como `group:`— costaba el conteo GLOBAL: las llaves de
  # `group_counts` son las que devolvió el GROUP BY, así que la búsqueda fallaba y el
  # encabezado caía al conteo de la página.
  def test_grouping_translates_the_band_label_through_an_i18n_scope
    I18n.backend.store_translations(:en, movies: { genres: { action: "Acción" } })
    @options = { group_counts: { "action" => 30 }, group_i18n_scope: "movies.genres" }

    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "action") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", text: "Acción (30) — showing 1")
  end

  def test_grouping_translates_the_band_label_through_a_callable
    @options = { group_counts: { "action" => 30 },
                 group_label: ->(value) { value.to_s.upcase } }

    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "action") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", text: "ACTION (30) — showing 1")
  end

  # El rótulo es del ENCABEZADO: el valor que lleva la fila —y con él el token del
  # seleccionar-todo del grupo— sigue siendo el crudo.
  def test_grouping_label_does_not_reach_the_group_selection_token
    @options = { selectable: true, group_label: ->(_value) { "Traducido" } }

    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "action", record_id: "1") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", text: "Traducido")
    assert_selector("[data-bulk-actions-group*='group-action-']", visible: :all)
  end

  def test_grouping_a_callable_wins_over_the_scope
    I18n.backend.store_translations(:en, movies: { genres: { action: "Acción" } })
    @options = { group_i18n_scope: "movies.genres", group_label: ->(_value) { "Del lambda" } }

    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "action") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", text: "Del lambda (1)")
  end

  # `nil` es la banda del NULL de SQL: ya tiene su clave traducible y no pasa por el hook.
  def test_grouping_the_null_band_keeps_its_own_key
    @options = { group_i18n_scope: "movies.genres" }

    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "action") { "<td>A</td>".html_safe }
      c.with_row(group: nil) { "<td>B</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", text: "Ungrouped (1)")
  end

  def test_grouping_rejects_a_group_label_that_is_not_callable
    error = assert_raises(ArgumentError) do
      Bali::Table::Component.new(group_label: "movies.genres")
    end

    assert_match "group_i18n_scope", error.message
  end

  def test_grouping_global_count_for_nil_group_value
    # A non-nil group is required to activate grouping (matches v1 behavior).
    @options = { group_counts: { "Norte" => 5, nil => 12 } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: nil) { "<td>B</td>".html_safe }
    end
    assert_selector("tr.bali-table-group-row td", text: "Ungrouped (12) — showing 1")
  end
end
