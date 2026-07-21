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

  def test_bulk_actions_renders_checkboxes_when_bulk_actions_provided
    @options = { bulk_actions: [ { name: "Delete", href: "/delete" } ] }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
    end
    assert_selector('input[type="checkbox"][data-table-target="toggleAll"]')
    assert_selector('input[type="checkbox"][data-table-target="checkbox"]')
  end

  def test_bulk_actions_renders_bulk_actions_container
    @options = { bulk_actions: [ { name: "Delete", href: "/delete" } ] }
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_selector(".bulk-actions-container")
    assert_selector('[data-table-target="actionsContainer"]')
  end

  def test_bulk_actions_renders_bulk_action_buttons
    @options = { bulk_actions: [ { name: "Delete Selected", href: "/bulk_delete" } ] }
    render_inline(component) do |c|
      c.with_header(name: "Name")
    end
    assert_selector('input[type="submit"][value="Delete Selected"]')
  end

  def test_bulk_actions_does_not_render_checkboxes_without_bulk_actions
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row { "<td>Row 1</td>".html_safe }
    end
    assert_no_selector('input[type="checkbox"][data-table-target="toggleAll"]')
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

  def test_bulk_actions_returns_true_when_bulk_actions_provided
    c = Bali::Table::Component.new(bulk_actions: [ { name: "Delete", href: "/delete" } ])
    assert(c.bulk_actions?)
  end

  def test_bulk_actions_returns_false_when_no_bulk_actions
    c = Bali::Table::Component.new
    refute(c.bulk_actions?)
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

  def test_grouping_header_colspan_matches_visible_headers_without_bulk_actions
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_header(name: "Amount")
      c.with_header(name: "Hidden", hidden: true)
      c.with_row(group: "Norte") { "<td>A</td><td>1</td>".html_safe }
    end
    assert_selector('tr.bali-table-group-row td[colspan="2"]')
  end

  def test_grouping_header_colspan_includes_bulk_actions_column
    @options = { bulk_actions: [ { name: "Delete", href: "/delete" } ] }
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
