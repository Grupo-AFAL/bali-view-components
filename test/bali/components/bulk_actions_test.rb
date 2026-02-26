# frozen_string_literal: true

require "test_helper"

class Bali_BulkActions_ComponentTest < ComponentTestCase
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
end
