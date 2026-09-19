# frozen_string_literal: true

require "test_helper"

# A form with both ways of narrowing at once: the advanced builder (which travels nested in
# `q[g][...]`) and a flat attribute. The bulk's round trip has to reproduce both.
class BulkActionsRoundTripFilterForm < Bali::FilterForm
  filter_attribute :name, type: :text
  filter_attribute :status, type: :select, options: [ %w[Draft draft], %w[Done done] ]

  attribute :name_cont
  attribute :status_eq
  # A date_range declared as an attribute: `result` applies it OUTSIDE Ransack. Since #966
  # `active_filters` includes it anyway (resolved, `start..end`); were it to lose it again, the bulk
  # would act on a superset of what is on screen.
  attribute :created_at, Bali::Types::DateRangeValue.new
end

# The other way of declaring a date_range: as a SIMPLE filter. That path already travels inside
# `active_filters`, so the re-emission must not add it — and cannot add it twice. `presets:` only
# exist here.
class BulkActionsSimpleDateRangeFilterForm < Bali::FilterForm
  filter_attribute :created_at, type: :date, input: :date_range, simple: true, advanced: false,
                   presets: %i[today this_month]
end

class BaliBulkActionsComponentTest < ComponentTestCase
  def setup
    @component = Bali::BulkActions::Component.new
  end

  def test_rendering_renders_bulk_actions_component_with_base_class
    render_inline(@component)
    assert_selector("div.bulk-actions-component")
  end

  def test_rendering_renders_with_stimulus_controller
    render_inline(@component)
    assert_selector("[data-controller='bulk-actions']")
  end

  def test_rendering_accepts_custom_classes
    render_inline(Bali::BulkActions::Component.new(class: "custom-class"))
    assert_selector("div.bulk-actions-component.custom-class")
  end

  def test_items_renders_items_with_correct_data_attributes
    render_inline(@component) do |c|
      c.with_item(record_id: 42) { "Content" }
    end
    assert_selector("[data-record-id='42']")
    assert_selector("[data-bulk-actions-target='item']")
    assert_selector("[data-action='click->bulk-actions#toggle']")
  end

  def test_items_renders_items_with_base_class
    render_inline(@component) do |c|
      c.with_item(record_id: 1) { "Content" }
    end
    assert_selector(".bulk-actions-item", text: "Content")
  end

  def test_items_accepts_custom_classes_on_items
    render_inline(@component) do |c|
      c.with_item(record_id: 1, class: "custom-item-class") { "Content" }
    end
    assert_selector(".bulk-actions-item.custom-item-class")
  end

  # A `selectAll` with `data-bulk-actions-group="<id>"` only reaches the items declaring that id.
  # With no `group:` no attribute is emitted, and with no attribute the item belongs to all of them.
  def test_items_carry_no_group_by_default
    render_inline(@component) do |c|
      c.with_item(record_id: 1) { "Content" }
    end
    assert_no_selector("[data-bulk-actions-group]")
  end

  def test_items_declare_the_groups_they_belong_to
    render_inline(@component) do |c|
      c.with_item(record_id: 1, group: "norte") { "Content" }
      c.with_item(record_id: 2, group: %w[norte tijuana]) { "Content" }
    end
    assert_selector("[data-record-id='1'][data-bulk-actions-group='norte']")
    assert_selector("[data-record-id='2'][data-bulk-actions-group='norte tijuana']")
  end

  def test_items_renders_multiple_items
    render_inline(@component) do |c|
      c.with_item(record_id: 1) { "Item 1" }
      c.with_item(record_id: 2) { "Item 2" }
      c.with_item(record_id: 3) { "Item 3" }
    end
    assert_selector(".bulk-actions-item", count: 3)
    assert_selector("[data-record-id='1']")
    assert_selector("[data-record-id='2']")
    assert_selector("[data-record-id='3']")
  end

  def test_actions_renders_actions_container_with_stimulus_target
    render_inline(@component) do |c|
      c.with_action(label: "Update", href: "/update")
    end
    assert_selector("[data-bulk-actions-target='actionsContainer']")
  end

  def test_actions_renders_selected_count_with_stimulus_target
    render_inline(@component) do |c|
      c.with_action(label: "Update", href: "/update")
    end
    assert_selector("[data-bulk-actions-target='selectedCount']", text: "0")
  end

  def test_actions_hides_actions_container_initially
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive")
    end
    assert_selector(".hidden[data-bulk-actions-target='actionsContainer']")
  end

  def test_actions_with_post_method_default_renders_as_a_form
    render_inline(@component) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector("form[action='/delete']")
    assert_button("Delete")
    assert_selector("input[name='selected_ids'][data-bulk-actions-target='bulkAction']", visible: false)
  end

  def test_actions_with_post_method_default_applies_variant_classes_to_submit_button
    render_inline(@component) do |c|
      c.with_action(label: "Delete", href: "/delete", variant: :error)
    end
    assert_selector("input.btn.btn-sm.btn-error")
  end

  # The shipped markup cannot depend on the host's configuration: the action's `form_with` declares
  # Rails' builder, so it renders the same with and without `default_form_builder = Bali::FormBuilder`
  # set by the host (#1137). Without that `builder:`, `form.submit` came out as
  # `<button class="btn btn-primary">`: the POST lost its `name="commit"` and the builder's
  # `btn-primary` ended up glued in front of the real variant
  # (`btn btn-primary btn btn-sm btn-error`). The `data-disable-with` comes back with the `<input>`,
  # but that is only a fact of the markup: rails-ujs reads it, and no app in the group has it.
  def test_an_actions_form_renders_the_same_under_the_hosts_default_builder
    render_action = lambda do
      render_inline(Bali::BulkActions::Action::Component.new(
        label: "Delete", href: "/delete", variant: :error
      )).to_html
    end

    with_rails_default = render_action.call
    with_bali_default = with_default_form_builder(Bali::FormBuilder) { render_action.call }

    assert_equal(with_rails_default, with_bali_default)
    # `page` is left holding the second render (the one under Bali's builder as the default).
    assert_selector("form[action='/delete'] input[type='submit'][name='commit'].btn.btn-error")
    assert_selector("form[action='/delete'] input[type='submit'][data-disable-with]")
  end

  # `builder:` goes BEFORE the `**form_options` splat on purpose: it is a default of the gem, not a
  # lock, so a `builder:` the host passes to `with_action` has to keep winning. It lived only in a
  # comment.
  def test_a_builder_passed_to_with_action_still_wins_over_the_gems_default
    render_inline(@component) do |c|
      c.with_action(label: "Delete", href: "/delete", variant: :error, builder: Bali::FormBuilder)
    end

    # Bali's builder markup: `submit` is a `<button>` inside its `div.inline`.
    assert_selector("form[action='/delete'] div.inline button[type='submit']", text: "Delete")
    assert_no_selector("form[action='/delete'] input[type='submit']")
  end

  def test_actions_with_delete_method_renders_as_a_form_with_hidden_method_field
    render_inline(@component) do |c|
      c.with_action(label: "Remove", href: "/remove", method: :delete)
    end
    assert_selector("form[action='/remove']")
    assert_selector("input[name='_method'][value='delete']", visible: false)
    assert_button("Remove")
  end

  def test_actions_with_get_method_renders_as_a_link
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get)
    end
    assert_link("Export", href: "/export")
    assert_selector("a[data-bulk-actions-target='bulkAction']")
  end

  def test_actions_with_get_method_applies_button_styling_to_link
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get, variant: :info)
    end
    assert_selector("a.btn.btn-info")
  end

  def test_actions_renders_multiple_actions
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive", variant: :info)
      c.with_action(label: "Delete", href: "/delete", variant: :error)
    end
    assert_button("Archive")
    assert_button("Delete")
  end

  def test_toolbar_variant_renders_the_contextual_bar_instead_of_the_floating_one
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector(".hidden.mb-4[data-bulk-actions-target='actionsContainer']")
    assert_no_selector(".fixed[data-bulk-actions-target='actionsContainer']")
  end

  def test_toolbar_variant_renders_a_clear_button_wired_to_the_controller
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector("button[data-action='bulk-actions#clear']", visible: :all)
    assert_no_selector("a[data-action='bulk-actions#clear']", visible: :all)
  end

  def test_toolbar_variant_renders_both_plural_labels_with_the_singular_hidden
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector("[data-bulk-actions-target='selectedLabelOne'].hidden", visible: :all)
    assert_selector("[data-bulk-actions-target='selectedLabelOther']", visible: :all)
    assert_selector("[data-bulk-actions-target='selectedCount']", text: "0", visible: :all)
  end

  def test_unknown_variant_falls_back_to_floating
    render_inline(Bali::BulkActions::Component.new(variant: :sidebar)) do |c|
      c.with_action(label: "Delete", href: "/delete")
    end
    assert_selector(".fixed[data-bulk-actions-target='actionsContainer']")
  end

  def test_standalone_false_does_not_emit_its_own_stimulus_controller
    # Two nested `bulk-actions` controllers split the targets between them: the bar would stop
    # seeing the rows and the counter would sit at 0 WITHOUT an error.
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false))
    assert_selector("div.bulk-actions-component")
    assert_no_selector("[data-controller='bulk-actions']")
  end

  def test_custom_data_attributes_survive_in_both_modes
    render_inline(Bali::BulkActions::Component.new(data: { foo: "bar" }))
    assert_selector("[data-foo='bar'][data-controller='bulk-actions']")

    render_inline(Bali::BulkActions::Component.new(standalone: false, data: { foo: "bar" }))
    assert_selector("[data-foo='bar']")
  end

  def test_combined_items_and_actions_renders_both_items_and_actions_together
    render_inline(@component) do |c|
      c.with_action(label: "Bulk Update", href: "/bulk_update")
      c.with_item(record_id: 1) { "Item 1" }
      c.with_item(record_id: 2) { "Item 2" }
    end
    assert_selector(".bulk-actions-component")
    assert_selector(".bulk-actions-item", count: 2)
    assert_button("Bulk Update")
  end

  # --- Per-action control (#724) ----------------------------------------------------------

  def test_a_control_renders_inside_the_actions_own_form_before_the_submit
    render_inline(@component) do |c|
      c.with_action(label: "Assign", href: "/assign") do |action|
        action.with_control do
          %(<select name="driver_id" class="select"><option value="1">Ana</option></select>).html_safe
        end
      end
    end

    assert_selector("form[action='/assign'] select[name='driver_id']", visible: :all)
    # Order matters: the submit goes last so the control comes first in the tab order.
    inputs = page.find("form[action='/assign']").all("select, input", visible: :all).map { |n| n[:name] }
    assert_equal(%w[selected_ids driver_id commit], inputs.compact.reject(&:empty?))
  end

  def test_a_control_on_a_get_action_raises_instead_of_dropping_the_value
    error = assert_raises(ArgumentError) do
      render_inline(@component) do |c|
        c.with_action(label: "Export", href: "/export", method: :get) do |action|
          action.with_control { %(<input type="text" name="format">).html_safe }
        end
      end
    end

    assert_match(/with_control/, error.message)
    assert_match(/method: :get/, error.message)
    assert_match(/Export/, error.message)
  end

  def test_a_get_action_without_a_control_still_renders_as_a_link
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get)
    end
    assert_link("Export", href: "/export")
  end

  # Every action is its own form and all of them emit the same field: with the id derived from the
  # name, a bar of three actions repeated `id="selected_ids"` three times in the document.
  def test_the_selected_ids_field_carries_no_id_so_several_actions_can_coexist
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive")
      c.with_action(label: "Delete", href: "/delete")
    end

    fields = page.all("input[name='selected_ids']", visible: :all)
    assert_equal(2, fields.size)
    assert(fields.none? { |field| field[:id].present? }, "el hidden de ids no debe llevar id")
  end

  # The guide promises that `data: { turbo_confirm: }` on the action goes through Bali's dialog:
  # that only works if the attribute lands on the `<form>`, which is where Turbo reads it.
  def test_data_attributes_reach_the_form_so_turbo_confirm_works
    render_inline(@component) do |c|
      c.with_action(label: "Borrar", href: "/borrar", data: { turbo_confirm: "¿Seguro?" })
    end

    assert_selector("form[action='/borrar'][data-turbo-confirm='¿Seguro?']", visible: :all)
  end

  # --- target: (#724) --------------------------------------------------------------------

  def test_target_reaches_the_form_of_a_post_action
    render_inline(@component) do |c|
      c.with_action(label: "Print", href: "/print", target: "_blank")
    end
    assert_selector("form[action='/print'][target='_blank']", visible: :all)
  end

  # `form_with` honours only a handful of loose options: a `target:` through **options was dropped
  # without warning, which is why it is a first-class option.
  def test_target_is_not_swallowed_the_way_a_bare_passthrough_was
    render_inline(@component) do |c|
      c.with_action(label: "Print", href: "/print")
    end
    assert_no_selector("form[target]", visible: :all)
  end

  def test_target_reaches_the_anchor_of_a_get_action
    render_inline(@component) do |c|
      c.with_action(label: "Export", href: "/export", method: :get, target: "_blank")
    end
    assert_selector("a[href='/export'][target='_blank']")
  end

  # The contextual row REPLACES the DataTable's toolbar in the very same slot: if they measure
  # differently, selecting a row shoves the listing. It used to (18px: `py-2` + `border`).
  def test_the_toolbar_row_declares_the_same_minimum_height_as_the_datatable_toolbar
    assert_includes(Bali::DataTable::Component::TOOLBAR_CLASSES,
                    Bali::BulkActions::Component::TOOLBAR_MIN_HEIGHT)

    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    bar = page.find("[data-bulk-actions-target='actionsContainer'] > div")
    assert_includes(bar[:class], Bali::BulkActions::Component::TOOLBAR_MIN_HEIGHT)
  end

  # The bar measures the same as the toolbar (32px), so an `sm` button —which measures EXACTLY that—
  # sits flush against the tint and looks cramped. `xs` leaves 4px of air without moving the height.
  # The floating variant does not live inside a fixed-height surface and keeps `sm`.
  def test_the_toolbar_row_sizes_its_actions_below_the_bar_height
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end
    assert_selector("input.btn.btn-xs[value='Borrar']")
    assert_no_selector(".btn-sm")

    render_inline(Bali::BulkActions::Component.new) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end
    assert_selector("input.btn.btn-sm[value='Borrar']")
  end

  def test_an_explicit_action_size_wins_over_the_one_the_bar_injects
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar", size: :lg)
    end
    assert_selector("input.btn.btn-lg[value='Borrar']")
  end

  # The outline uses `ring` (box-shadow) and no vertical padding precisely because a `border`/`py-*`
  # do take up layout and would bring the jump back.
  def test_the_toolbar_row_outline_costs_no_vertical_space
    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    classes = page.find("[data-bulk-actions-target='actionsContainer'] > div")[:class]
    assert_includes(classes, "ring-1")
    refute_match(/\bborder\b/, classes)
    refute_match(/\bpy-\d/, classes)
  end
end

# The "act on the N filtered ones" contract (#724): what is painted, what travels in the POST, and
# that what travels reproduces the SAME scope as the listing.
class BaliBulkActionsSelectAllFilteredTest < ComponentTestCase
  FILTER_PAIRS = [
    [ "q[g][0][m]", "or" ],
    [ "q[g][0][name_cont]", "Iron" ],
    [ "q[status_eq]", "draft" ]
  ].freeze

  def bar(total_count: 120, filter_params: FILTER_PAIRS, **options)
    Bali::BulkActions::Component.new(total_count: total_count, filter_params: filter_params,
                                     **options)
  end

  # --- What is painted --------------------------------------------------------------------

  def test_without_a_total_count_nothing_of_the_mode_exists
    render_inline(Bali::BulkActions::Component.new(filter_params: FILTER_PAIRS)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    assert_no_selector("[data-bulk-actions-target='selectAllOffer']", visible: :all)
    assert_no_selector("input[name='select_all_filtered']", visible: :all)
    # Nor the filters: with no flag to switch them on, they would only be noise in the POST.
    assert_no_selector("input[name='q[status_eq]']", visible: :all)
  end

  def test_the_offer_and_the_notice_carry_n_from_the_server
    render_inline(bar) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    offer = page.find("[data-bulk-actions-target='selectAllOffer']", visible: :all)
    assert_equal("120", offer["data-total-count"])
    assert_selector("[data-bulk-actions-target='selectAllOffer'] button", text: "Select all 120 results",
                    visible: :all)
    assert_selector("[data-bulk-actions-target='selectAllNotice']",
                    text: "All 120 results are selected", visible: :all)
  end

  # Both start hidden: the offer only applies with the whole page ticked, and the notice only inside
  # the mode. The JS decides; the server cannot know either of those two things.
  def test_the_offer_and_the_notice_start_hidden
    render_inline(bar) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    assert_selector("[data-bulk-actions-target='selectAllOffer'].hidden", visible: :all)
    assert_selector("[data-bulk-actions-target='selectAllNotice'].hidden", visible: :all)
  end

  def test_the_offer_is_a_button_because_it_changes_state_instead_of_navigating
    render_inline(bar) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    assert_selector("button[data-action='bulk-actions#selectAllFiltered']", visible: :all)
    assert_no_selector("a[data-action='bulk-actions#selectAllFiltered']", visible: :all)
  end

  # --- What travels in the POST ----------------------------------------------------------

  def test_every_action_form_carries_the_flag_off_and_the_active_filters
    render_inline(bar) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
      c.with_action(label: "Archivar", href: "/archivar")
    end

    flags = page.all("input[name='select_all_filtered']", visible: :all)
    assert_equal(2, flags.size)
    assert(flags.all? { |flag| flag.value == "false" }, "el flag arranca apagado")
    assert(flags.all? { |flag| flag[:id].blank? }, "el flag no debe llevar id: se repite por form")
    assert_selector("[data-bulk-actions-target='selectAllFilteredField']", count: 2, visible: :all)

    FILTER_PAIRS.each do |name, value|
      assert_selector("form[action='/borrar'] input[name='#{name}'][value='#{value}']", visible: :all)
      assert_selector("form[action='/archivar'] input[name='#{name}'][value='#{value}']", visible: :all)
    end
  end

  # A GET action has no hidden fields, so the filters travel in its href — and any the href already
  # carried are discarded: the listing's current state is what rules.
  def test_a_get_action_carries_the_filters_in_its_href
    render_inline(bar) do |c|
      c.with_action(label: "Exportar", href: "/exportar?format=csv&q%5Bname_cont%5D=viejo",
                    method: :get)
    end

    query = Rack::Utils.parse_nested_query(URI.parse(page.find("a")[:href]).query)
    assert_equal("csv", query["format"])
    assert_equal("Iron", query.dig("q", "g", "0", "name_cont"))
    assert_equal("draft", query.dig("q", "status_eq"))
  end

  # --- The round trip: what travels reproduces the listing ---------------------------------

  def test_the_filters_a_data_table_emits_rebuild_the_very_same_scope
    tenant = Tenant.create(name: "Round trip")
    iron_1 = tenant.movies.create(name: "Iron man 1", status: 0)
    iron_2 = tenant.movies.create(name: "Iron man 2", status: 0)
    tenant.movies.create(name: "Snatch", status: 0)

    listing_params = ActionController::Parameters.new(
      q: { g: { "0" => { m: "or", name_cont: "Iron" } }, status_eq: "draft" }
    )
    listing = BulkActionsRoundTripFilterForm.new(tenant.movies, listing_params)
    assert_equal([ iron_1.id, iron_2.id ].sort, listing.result.pluck(:id).sort)

    render_inline(
      Bali::BulkActions::Component.new(
        total_count: listing.result.count,
        filter_params: Bali::Filters::ActiveFilterParams.for_filter_form(listing)
      )
    ) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    # Exactly what the browser would post from that form.
    posted = Rack::Utils.parse_nested_query(
      page.all("form[action='/borrar'] input[type=hidden]", visible: :all)
          .reject { |input| %w[authenticity_token selected_ids].include?(input[:name]) }
          .map { |input| "#{CGI.escape(input[:name])}=#{CGI.escape(input.value.to_s)}" }
          .join("&")
    )
    assert_equal("false", posted["select_all_filtered"])

    rebuilt = BulkActionsRoundTripFilterForm.new(
      tenant.movies, ActionController::Parameters.new(posted)
    )
    assert_equal(listing.result.pluck(:id).sort, rebuilt.result.pluck(:id).sort)
  end

  # A `date_range` declared as an attribute does NOT go through Ransack: `result` applies it apart.
  # Before #966 `active_filters` excluded it by construction and the re-emission lost it: the listing
  # showed 1 record and the server re-derived 2 — the bulk acting on a SUPERSET of what is on
  # screen, which at scale is a destroy_all reaching exactly what the date filter excluded.
  def test_a_date_range_filter_survives_the_round_trip
    tenant = Tenant.create(name: "Date range")
    reciente = tenant.movies.create(name: "Iron man 3", status: 0)
    reciente.update_column(:created_at, Time.zone.parse("2026-03-15 12:00"))
    vieja = tenant.movies.create(name: "Iron man 1", status: 0)
    vieja.update_column(:created_at, Time.zone.parse("2020-01-05 12:00"))

    listing_params = ActionController::Parameters.new(
      q: { name_cont: "Iron", created_at: "2026-01-01..2026-12-31" }
    )
    listing = BulkActionsRoundTripFilterForm.new(tenant.movies, listing_params)
    assert_equal([ reciente.id ], listing.result.pluck(:id))

    pairs = Bali::Filters::ActiveFilterParams.for_filter_form(listing)
    posted = Rack::Utils.parse_nested_query(
      pairs.map { |name, value| "#{CGI.escape(name.to_s)}=#{CGI.escape(value.to_s)}" }.join("&")
    )
    rebuilt = BulkActionsRoundTripFilterForm.new(
      tenant.movies, ActionController::Parameters.new(posted)
    )

    assert_equal(listing.result.pluck(:id), rebuilt.result.pluck(:id),
                 "los pares re-emitidos tienen que reproducir el recorte por fecha")
  end

  # A date_range declared as a SIMPLE filter travels inside `active_filters` with the RAW value. The
  # re-emission cannot add it again: two hidden fields with the same `name` and the server keeps one,
  # silently. Today that holds because the two `active_filters` paths (resolved attribute and raw
  # simple) collide on the SAME key and the simple one wins — if that shape changes, this test is
  # what warns.
  def test_a_simple_date_range_is_emitted_exactly_once
    listing = BulkActionsSimpleDateRangeFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { created_at: "this_month" })
    )

    pairs = Bali::Filters::ActiveFilterParams.for_filter_form(listing)
    created_at = pairs.select { |name, _| name == "q[created_at]" }

    assert_equal(1, created_at.size, "un date_range simple se emite UNA vez: #{pairs.inspect}")
    # And it travels as a TOKEN, not as the already-resolved range: `active_filters` serves this path
    # with the raw value, so the server resolves it again against its own clock.
    assert_equal("this_month", created_at.first.last)
  end

  # --- The DataTable wires it on its own --------------------------------------------------

  def test_a_data_table_feeds_n_from_its_pagy_and_the_filters_from_its_filter_form
    filter_form = BulkActionsRoundTripFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { name_cont: "Iron" })
    )

    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: filter_form,
                                     pagy: Pagy::Offset.new(count: 47, page: 1, limit: 10))
    ) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Borrar", href: "/borrar") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_equal("47", page.find("[data-bulk-actions-target='selectAllOffer']",
                                 visible: :all)["data-total-count"])
    assert_selector("form[action='/borrar'] input[name='q[name_cont]'][value='Iron']", visible: :all)
  end

  # Countless pagination: `count` is nil by design, so there is no N to offer. Offering to "select
  # the results" without knowing how many they are promises something that cannot be measured.
  def test_a_countless_pagy_offers_nothing
    render_inline(
      Bali::DataTable::Component.new(url: "/movies", pagy: Pagy::Offset.new(count: 0, page: 1, limit: 10))
    ) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Borrar", href: "/borrar") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector("[data-bulk-actions-target='selectAllOffer']", visible: :all)
    assert_no_selector("input[name='select_all_filtered']", visible: :all)
  end

  def test_filter_params_accepts_a_nested_hash
    render_inline(
      Bali::BulkActions::Component.new(total_count: 5, filter_params: { q: { name_cont: "Iron" } })
    ) { |c| c.with_action(label: "Borrar", href: "/borrar") }

    assert_selector("input[name='q[name_cont]'][value='Iron']", visible: :all)
  end

  # An action mounted by hand, outside the bar, normalises the same way: `Array(hash)` left it as ONE
  # hidden field called `q` with the hash's `to_s` inside — a POST that looks well formed and filters
  # nothing.
  def test_an_action_mounted_on_its_own_normalizes_a_nested_hash_too
    render_inline(
      Bali::BulkActions::Action::Component.new(
        label: "Borrar", href: "/borrar",
        select_all_filtered: true, filter_params: { q: { name_cont: "Iron" } }
      )
    )

    assert_selector("input[name='q[name_cont]'][value='Iron']", visible: :all)
    assert_no_selector("input[name='q']", visible: :all)
  end

  def test_a_filter_params_shape_that_cannot_be_serialized_says_so
    error = assert_raises(ArgumentError) do
      Bali::BulkActions::Component.new(total_count: 5, filter_params: "q[name_cont]=Iron")
    end

    assert_match(/filter_params/, error.message)
    assert_match(/nested hash/, error.message)
  end
end
