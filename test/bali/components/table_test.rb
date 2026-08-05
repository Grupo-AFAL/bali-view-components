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

  def test_grouping_header_colspan_includes_the_selectable_column
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_header(name: "Amount")
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td><td>1</td>".html_safe }
    end
    assert_selector('tr.bali-table-group-row td[colspan="3"]')
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
