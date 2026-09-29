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

  # `sort_link` builds the href with `url_for`, so it needs a ROUTABLE request: in the bare
  # context of a component test there is no controller and no action, and it raises
  # UrlGenerationError before rendering anything. Same pattern as data_table_test.rb:420 and
  # view_switch_test.rb:64 — every test that renders a sortable header goes through here.
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

  # Ransack only painted an arrow on the SORTED column (`default_arrow` is nil): a sortable column
  # looked identical to one that is not. This is the assertion that pins it.
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

  # `aria-sort` announces the state exactly once: the icon is decoration.
  def test_headers_hide_the_sort_indicator_from_assistive_tech
    render_sortable_table do |c|
      c.with_header(name: "Name", sort: :name)
    end
    assert_selector("th a.sort_link span[aria-hidden='true']")
  end

  # `sort_link` merges into the HREF every option that is not class/data (`title:` comes out as
  # `&title=...`): if somebody "improves" the link with a new option, this catches it.
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

  # #1085 — with a real FilterForm, not a Struct: the defect was that the advanced panel never
  # reached `active_filters?`, so a listing narrowed to zero FROM THE PANEL offered its
  # no-records-yet empty state, first-one call to action and all, over a whole catalogue.
  def test_empty_states_reads_the_advanced_panel_as_filtered
    grouped = ActionController::Parameters.new(q: { g: { "0" => { name_cont: "NO_EXISTE" } } })
    @options = { form: Bali::FilterForm.new(Movie.all, grouped) }

    render_inline(component) { |c| c.with_new_record_link(name: "Add", href: "#", modal: false) }

    assert_selector(".empty-table p", text: "No Results")
    assert_no_selector(".empty-table a", text: "Add")
  end

  def test_empty_states_still_reads_an_untouched_advanced_panel_as_empty
    grouped = ActionController::Parameters.new(q: { g: { "0" => { name_cont: "" } } })
    @options = { form: Bali::FilterForm.new(Movie.all, grouped) }

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

  # `bulk_actions:` would fall into `**options` and come out as an attribute of the `<table>`: the
  # table would look fine, with no checkbox column and no bar. The guard exists so it blows up.
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
    # The `<tr>` IS the item: it carries the record id and the `selected` class. The cell's
    # checkbox only fires the action.
    @options = { selectable: true }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(record_id: 1) { "<td>Row 1</td>".html_safe }
    end
    assert_selector('tr[data-bulk-actions-target="item"][data-record-id="1"] td input[type="checkbox"][value="1"]')
    assert_selector('tr[data-record-id="1"] td input[data-action="change->bulk-actions#toggleItem"]')
  end

  def test_the_empty_state_spans_the_selection_column_too
    # `headers.count` ignored the checkbox column: the empty state came out one column short and
    # off-centre on every listing filtered to zero.
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
    # Without it, N rows give N controls with the SAME accessible name, indistinguishable in a
    # screen reader's forms rotor.
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

  # The `table` controller was deleted in v3: `bulk-actions` drives the selection from an
  # ancestor. An orphan target here would be a checkbox that fires nothing.
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
  # Selection by subgroup (#1047)
  # ---------------------------------------------------------------------------

  # Without `select_group:` the markup comes out as it did: a select-all with no group reaches the
  # controller's WHOLE selection, which with a single table is what it always was.
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

  # Both ids at once, space-separated like classes: the table's header ticks all 3 rows, each
  # group's header only its own.
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

  # A group value that turns up again further down is THE SAME group: its select-all ticks both
  # runs, which is what its label says.
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

  # A checkbox that would tick nothing is a dead control: the cell is painted anyway, to hold the
  # alignment, but empty.
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

  # The left-hand accent moves to the checkbox cell, which becomes the first one.
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
  # Rows outside the selection (#1047)
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

  # The cell is painted empty: without it that row's columns shift one position.
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

  # `skip_tr` and the selection still fight each other —the row cannot carry the record id if
  # there is no `<tr>` to carry it— but a row that opted out of the selection no longer does.
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

  # You can only opt out of the selection, never in: the column and the select-all are painted by
  # the TABLE, so a selectable row in there would be a loose checkbox with the columns shifted one
  # position.
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

  # `id:` identifies the COMPONENT, and the component's root is the `<div class="table-component">`
  # (the `**options` convention from docs/reference/component-patterns.md). It is the only key of
  # `**options` that does NOT reach the `<table>`: `row_id_prefix` and `empty_table_row_id` hang
  # off it, and it is the one `getElementById`, `turbo_stream.replace` and an anchor already
  # resolved by document order. Emitting it on the `<table>` too was invalid HTML (#1157).
  def test_custom_id_lands_only_on_the_container
    @options = { id: "my-table" }
    render_inline(component)
    assert_selector("div#my-table.table-component", count: 1)
    assert_no_selector("table#my-table")
    # The derived id still hangs off the same value: the extraction moved where `container_id`
    # reads it from, not what it is worth.
    assert_selector("tr#my-table-empty-table-row")
  end

  def test_custom_id_is_not_emitted_twice
    @options = { id: "my-table" }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row { "<td>A</td>".html_safe }
    end

    ids = page.native.css("[id]").map { |node| node["id"] }
    assert_equal(ids.uniq.size, ids.size, "ningún id del componente debe repetirse: #{ids.inspect}")
    assert_includes(ids, "my-table")
  end

  # `table_container:` paints the `<div>` AFTER the template's `id: container_id`, so an `id:`
  # there wins the container's attribute but does not feed `container_id`: the derived ids still
  # come out of the top-level `id:`. With both together, then, the top-level id appears on no
  # element at all — before #1157 it appeared on the `<table>`, which is precisely the emission
  # this fix removes. That is today's contract, not a recommendation: the component's identity is
  # asked for with `id:`, and `table_container:` takes classes and data.
  def test_a_container_id_option_wins_the_attribute_but_not_the_derived_ids
    @options = { id: "my-table", table_container: { id: "wrapper" } }
    render_inline(component)

    assert_selector("div#wrapper.table-component", count: 1)
    assert_no_selector("#my-table")
    assert_selector("tr#my-table-empty-table-row")
  end

  # And with no top-level `id:`, `container_id` stays nil even when `table_container:` carries one:
  # the empty `<tr>` comes out bare and the row prefix is random. Pinned because from this PR on
  # `table_container:` is documented API, and because it is the contract the issue's followup
  # proposes to change (a `||` to `@table_container_options[:id]`).
  def test_a_container_id_option_alone_does_not_feed_the_derived_ids
    @options = { table_container: { id: "wrapper" } }
    render_inline(component)

    assert_selector("div#wrapper.table-component", count: 1)
    assert_selector("tr#empty-table-row")
    assert_no_selector("tr#wrapper-empty-table-row")
  end

  # The visible consequence of the above: the row ids of collapsible groups come out of the random
  # prefix, not out of the container's id, so the HTML is not idempotent across renders. It is
  # pre-existing and filed as a followup; pinned so the fix has a test to change.
  def test_a_container_id_option_does_not_make_the_collapsible_row_ids_deterministic
    render_collapsible(table_container: { id: "wrapper" }) do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end

    row_id = page.find("tbody tr[data-table-groups-target='row']")["id"]
    assert_match(/\Atable-[0-9a-f]{6}-/, row_id, "el prefijo de fila debería ser el aleatorio")
    refute_match(/\Awrapper-/, row_id)
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

  # With selection on, the checkbox column is taken by the group's select-all: the label covers the
  # rest and across the two cells the row still measures the same.
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

  # #1086 — the band was labelled with the database value (`table`, `view`), and translating it the
  # obvious way —passing the label as `group:`— cost the GLOBAL count: the keys of `group_counts`
  # are the ones the GROUP BY returned, so the lookup missed and the header fell back to the page's
  # count.
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

  # The label belongs to the HEADER: the value the row carries —and with it the group select-all's
  # token— is still the raw one.
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

  # `nil` is SQL's NULL band: it already has its own translatable key and does not go through the hook.
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

  # ---------------------------------------------------------------------------
  # Grupos plegables
  # ---------------------------------------------------------------------------

  def render_collapsible(**options, &block)
    @options = { collapsible_groups: true }.merge(options)
    render_inline(component) do |c|
      c.with_header(name: "Name")
      block.call(c)
    end
  end

  # Without the option, a grouped table comes out as it did: no button, no controller, no token and
  # no ids on the rows. It is what guarantees a host on v3.3.1 sees nothing different.
  def test_grouped_tables_carry_no_collapse_markup_unless_asked_for
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end

    assert_no_selector("[data-controller]")
    assert_no_selector("tr.bali-table-group-row button")
    assert_no_selector("[data-group-token]")
    assert_no_selector("tbody tr[id]")
  end

  def test_collapsible_groups_turn_each_band_into_a_disclosure_button
    render_collapsible do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte") { "<td>B</td>".html_safe }
      c.with_row(group: "Sur") { "<td>C</td>".html_safe }
    end

    assert_selector(".table-component[data-controller='table-groups']")
    assert_selector("tr.bali-table-group-row td button[type='button'][aria-expanded='true']" \
                    "[data-table-groups-target='trigger'][data-action='click->table-groups#toggle']",
                    count: 2)
    assert_selector("tr.bali-table-group-row button", text: "Norte (2)")
    assert_selector("tr.bali-table-group-row button", text: "Sur (1)")
    assert_selector("tr.bali-table-group-row button svg")
  end

  # The button controls exactly the rows of its run: the ids it lists are those rows', and each row
  # carries the token the controller finds it by.
  def test_the_trigger_controls_the_rows_of_its_group
    render_collapsible(id: "leaders") do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte") { "<td>B</td>".html_safe }
      c.with_row(group: "Sur") { "<td>C</td>".html_safe }
    end

    token = Bali::Table::Component.new.group_token("Norte")
    trigger = page.find("tr.bali-table-group-row button[data-group-token='#{token}']")
    controlled = trigger["aria-controls"].split(" ")

    assert_equal([ "leaders-#{token}-row-1", "leaders-#{token}-row-2" ], controlled)
    controlled.each do |id|
      assert_selector("tbody tr##{id}[data-table-groups-target='row'][data-group-token='#{token}']")
    end
    assert_selector("tbody tr[data-group-token='#{token}']", count: 2)
    assert_selector("tbody tr[data-group-token]", count: 3)
  end

  def test_a_row_id_given_by_the_host_is_the_one_the_trigger_controls
    render_collapsible do |c|
      c.with_row(group: "Norte", id: "movie_7") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row button[aria-controls='movie_7']")
    assert_selector("tbody tr#movie_7[data-table-groups-target='row']")
  end

  # With no `id:` on the table the prefix is random: two collapsible tables on the same page cannot
  # share row ids, and `aria-controls` would point at the wrong one.
  def test_row_ids_get_a_random_prefix_when_the_table_has_no_id
    render_collapsible do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end

    id = page.find("tbody tr[data-table-groups-target='row']")[:id]
    assert_match(/\Atable-\h{6}-group-norte-\h{6}-row-1\z/, id)
    assert_selector("tr.bali-table-group-row button[aria-controls='#{id}']")
  end

  # The initial state goes on the button and NEVER on the row: the controller hides the rows on
  # connect, so without JS everything stays visible.
  def test_collapsed_groups_lists_the_values_that_are_born_folded
    render_collapsible(collapsed_groups: [ "Sur" ]) do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Sur") { "<td>B</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row button[aria-expanded='true']", text: "Norte")
    assert_selector("tr.bali-table-group-row button[aria-expanded='false']", text: "Sur")
    assert_no_selector("tbody tr[hidden]", visible: :all)
  end

  def test_collapsed_groups_matches_a_symbol_value_against_a_string_entry
    render_collapsible(collapsed_groups: %w[active]) do |c|
      c.with_row(group: :active) { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row button[aria-expanded='false']")
  end

  def test_collapsed_groups_takes_a_callable_over_the_raw_value
    render_collapsible(collapsed_groups: ->(value) { value == "Sur" }) do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Sur") { "<td>B</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row button[aria-expanded='true']", text: "Norte")
    assert_selector("tr.bali-table-group-row button[aria-expanded='false']", text: "Sur")
  end

  def test_collapsed_groups_true_folds_every_band
    render_collapsible(collapsed_groups: true) do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: nil) { "<td>B</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row button[aria-expanded='false']", count: 2)
  end

  def test_collapsed_groups_without_collapsible_groups_raises
    error = assert_raises(ArgumentError) { Bali::Table::Component.new(collapsed_groups: [ "Sur" ]) }

    assert_match("collapsible_groups: true", error.message)
  end

  # `group_header:` would fall into `**options` and come out as an attribute of the `<table>` (#1081).
  def test_group_header_as_a_keyword_raises_instead_of_leaking_to_the_table
    error = assert_raises(ArgumentError) { Bali::Table::Component.new(group_header: "x") }

    assert_match("with_group_header", error.message)
  end

  # The block receives the group already resolved —translated label, global count— so neither has
  # to be redone, and what it returns replaces the default text.
  def test_with_group_header_paints_the_band_from_the_block
    @options = { group_counts: { "action" => 30 }, group_label: ->(value) { value.to_s.upcase } }
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_group_header do |group|
        "<span class='dot'></span><b>#{group.label}</b> <i>#{group.count}</i> " \
        "#{group.rows.size} #{group.value}".html_safe
      end
      c.with_row(group: "action") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td span.dot")
    assert_selector("tr.bali-table-group-row td b", text: "ACTION")
    assert_selector("tr.bali-table-group-row td i", text: "30")
    assert_selector("tr.bali-table-group-row td", text: "ACTION 30 1 action")
    assert_no_selector("tr.bali-table-group-row td", text: "(30)")
  end

  def test_with_group_header_count_falls_back_to_the_run_size
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_group_header { |group| "#{group.label}: #{group.count}" }
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte") { "<td>B</td>".html_safe }
      c.with_row(group: nil) { "<td>C</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row td", text: "Norte: 2")
    assert_selector("tr.bali-table-group-row td", text: "Ungrouped: 1")
  end

  def test_with_group_header_escapes_what_the_block_returns_unless_it_is_safe
    render_inline(component) do |c|
      c.with_header(name: "Name")
      c.with_group_header { |group| "<b>#{group.label}</b>" }
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end

    assert_no_selector("tr.bali-table-group-row td b")
    assert_selector("tr.bali-table-group-row td", text: "<b>Norte</b>")
  end

  # With collapsing on, the block's content is the button's NAME: it goes inside, next to the
  # chevron.
  def test_with_group_header_goes_inside_the_collapse_trigger
    render_collapsible do |c|
      c.with_group_header { |group| "<em>#{group.label}</em>".html_safe }
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
    end

    assert_selector("tr.bali-table-group-row button span.icon-component + em", text: "Norte")
  end

  # The group's checkbox stays in ITS cell, outside the button —a control inside another is invalid
  # HTML— and the row carries both attributes: the selection one and the collapse one. That the
  # select-all ticks folded rows is covered by Cypress: the selection controller does not look at
  # visibility.
  def test_collapsible_and_selectable_keep_the_group_checkbox_outside_the_trigger
    render_collapsible(selectable: true, collapsed_groups: true) do |c|
      c.with_row(record_id: 1, group: "Norte") { "<td>A</td>".html_safe }
    end

    token = Bali::Table::Component.new(selectable: true).group_token("Norte")
    assert_selector("tr.bali-table-group-row td.w-4 input[data-bulk-actions-group='#{token}']")
    assert_no_selector("tr.bali-table-group-row button input")
    assert_selector("tr[data-record-id='1'][data-bulk-actions-group='#{token}'][data-group-token='#{token}']")
  end

  # A `skip_tr: true` row paints its own `<tr>`: no id, no token, and the button does not list it.
  def test_skip_tr_rows_stay_out_of_the_collapse
    render_collapsible do |c|
      c.with_row(group: "Norte") { "<td>A</td>".html_safe }
      c.with_row(group: "Norte", skip_tr: true) { "<tr class='mine'><td>B</td></tr>".html_safe }
    end

    assert_selector("tr.mine")
    assert_no_selector("tr.mine[data-group-token]")
    assert_equal(1, page.find("tr.bali-table-group-row button")["aria-controls"].split(" ").size)
  end

  def test_collapsible_groups_without_any_group_renders_a_plain_table
    render_collapsible do |c|
      c.with_row { "<td>A</td>".html_safe }
    end

    assert_no_selector("tr.bali-table-group-row")
    assert_no_selector("[data-controller]")
    assert_no_selector("[data-group-token]")
    assert_no_selector("tbody tr[id]")
  end
end
