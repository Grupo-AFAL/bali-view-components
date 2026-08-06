# frozen_string_literal: true

require "test_helper"

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
    # Dos controladores `bulk-actions` anidados se reparten los targets: la barra dejaría
    # de ver las filas y el contador quedaría en 0 SIN error.
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

  # --- Control por acción (#724) ---------------------------------------------------------

  def test_a_control_renders_inside_the_actions_own_form_before_the_submit
    render_inline(@component) do |c|
      c.with_action(label: "Assign", href: "/assign") do |action|
        action.with_control do
          %(<select name="driver_id" class="select"><option value="1">Ana</option></select>).html_safe
        end
      end
    end

    assert_selector("form[action='/assign'] select[name='driver_id']", visible: :all)
    # El orden importa: el submit va último para que el control quede antes en el tab order.
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

  # Cada acción es su propio form y todas emiten el mismo campo: con el id derivado del name,
  # una barra de tres acciones repetía `id="selected_ids"` tres veces en el documento.
  def test_the_selected_ids_field_carries_no_id_so_several_actions_can_coexist
    render_inline(@component) do |c|
      c.with_action(label: "Archive", href: "/archive")
      c.with_action(label: "Delete", href: "/delete")
    end

    fields = page.all("input[name='selected_ids']", visible: :all)
    assert_equal(2, fields.size)
    assert(fields.none? { |field| field[:id].present? }, "el hidden de ids no debe llevar id")
  end

  # --- target: (#724) --------------------------------------------------------------------

  def test_target_reaches_the_form_of_a_post_action
    render_inline(@component) do |c|
      c.with_action(label: "Print", href: "/print", target: "_blank")
    end
    assert_selector("form[action='/print'][target='_blank']", visible: :all)
  end

  # `form_with` solo respeta un puñado de opciones sueltas: un `target:` por **options se
  # perdía sin avisar, que es la razón de que sea opción de primera clase.
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

  # La fila contextual REEMPLAZA a la toolbar del DataTable en su mismo hueco: si miden
  # distinto, seleccionar una fila empuja el listado. Antes pasaba (18px: `py-2` + `border`).
  def test_the_toolbar_row_declares_the_same_minimum_height_as_the_datatable_toolbar
    assert_includes(Bali::DataTable::Component::TOOLBAR_CLASSES,
                    Bali::BulkActions::Component::TOOLBAR_MIN_HEIGHT)

    render_inline(Bali::BulkActions::Component.new(variant: :toolbar, standalone: false)) do |c|
      c.with_action(label: "Borrar", href: "/borrar")
    end

    bar = page.find("[data-bulk-actions-target='actionsContainer'] > div")
    assert_includes(bar[:class], Bali::BulkActions::Component::TOOLBAR_MIN_HEIGHT)
  end

  # La barra mide lo mismo que la toolbar (32px), así que un botón `sm` —que mide EXACTAMENTE
  # eso— queda a ras del tinte y se ve apretado. `xs` deja 4px de aire sin mover el alto.
  # La flotante no vive dentro de una superficie de alto fijo y conserva `sm`.
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

  # El contorno va con `ring` (box-shadow) y sin padding vertical justamente porque un
  # `border`/`py-*` sí ocupan layout y devolverían el salto.
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
