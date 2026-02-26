# frozen_string_literal: true

require "test_helper"

class BaliSortableListComponentTest < ComponentTestCase
  def test_base_classes_constant_is_frozen
    assert(Bali::SortableList::Component::BASE_CLASSES.frozen?)
  end

  def test_base_classes_constant_contains_expected_classes
    assert_includes(Bali::SortableList::Component::BASE_CLASSES, "sortable-list-component")
    assert_includes(Bali::SortableList::Component::BASE_CLASSES, "p-0")
  end
  def test_defaults_constant_is_frozen
    assert(Bali::SortableList::Component::DEFAULTS.frozen?)
  end

  def test_defaults_constant_contains_default_values
    assert_equal("position", Bali::SortableList::Component::DEFAULTS[:position_param_name])
    assert_equal("list_id", Bali::SortableList::Component::DEFAULTS[:list_param_name])
    assert_equal(:html, Bali::SortableList::Component::DEFAULTS[:response_kind])
    assert_equal(false, Bali::SortableList::Component::DEFAULTS[:disabled])
    assert_equal(150, Bali::SortableList::Component::DEFAULTS[:animation])
  end
  def test_rendering_renders_a_sortable_component_with_base_classes
    render_inline(Bali::SortableList::Component.new)
    assert_selector("div.sortable-list-component")
    assert_selector('div[data-controller="sortable-list"]')
    assert_selector('div[data-sortable-list-disabled-value="false"]')
  end

  def test_rendering_renders_with_content_block
    render_inline(Bali::SortableList::Component.new) { "Custom content" }
    assert_text("Custom content")
  end
  def test_disabled_option_renders_disabled_sortable_component
    render_inline(Bali::SortableList::Component.new(disabled: true))
    assert_selector('div[data-sortable-list-disabled-value="true"]')
  end

  def test_disabled_option_renders_enabled_by_default
    render_inline(Bali::SortableList::Component.new)
    assert_selector('div[data-sortable-list-disabled-value="false"]')
  end
  def test_items_slot_renders_sortable_component_with_items
    render_inline(Bali::SortableList::Component.new) do |c|
      c.with_item(update_url: "/items/1") { "Item 1" }
      c.with_item(update_url: "/items/2") { "Item 2" }
      c.with_item(update_url: "/items/3", item_pull: false) { "Item 3" }
    end
    assert_selector("div.sortable-item", count: 3)
    assert_selector('div.sortable-item[data-sortable-update-url="/items/1"]')
    assert_selector('div.sortable-item[data-sortable-update-url="/items/2"]')
    assert_selector('div.sortable-item[data-sortable-update-url="/items/3"]')
    assert_selector('div.sortable-item[data-sortable-item-pull="true"]', count: 2)
    assert_selector('div.sortable-item[data-sortable-item-pull="false"]', count: 1)
  end
  def test_all_stimulus_values_passes_all_values_to_stimulus_controller
    options = {
      animation: 200,
      disabled: true,
      group_name: "group_test_name",
      handle: ".handle",
      list_id: 10,
      list_param_name: "custom_list_id",
      resource_name: "tasks",
      response_kind: :turbo_stream,
      position_param_name: "custom_position"
    }
    render_inline(Bali::SortableList::Component.new(**options))
    assert_selector('div[data-sortable-list-animation-value="200"]')
    assert_selector('div[data-sortable-list-disabled-value="true"]')
    assert_selector('div[data-sortable-list-group-name-value="group_test_name"]')
    assert_selector('div[data-sortable-list-handle-value=".handle"]')
    assert_selector('div[data-sortable-list-list-id-value="10"]')
    assert_selector('div[data-sortable-list-list-param-name-value="custom_list_id"]')
    assert_selector('div[data-sortable-list-resource-name-value="tasks"]')
    assert_selector('div[data-sortable-list-response-kind-value="turbo_stream"]')
    assert_selector('div[data-sortable-list-position-param-name-value="custom_position"]')
  end
  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::SortableList::Component.new(class: "custom-class"))
    assert_selector("div.sortable-list-component.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::SortableList::Component.new(data: { testid: "sortable-test" }))
    assert_selector('div[data-testid="sortable-test"]')
  end

  def test_options_passthrough_accepts_id_attribute
    render_inline(Bali::SortableList::Component.new(id: "my-sortable"))
    assert_selector("div#my-sortable")
  end
  def test_cursor_styling_adds_cursor_grab_to_items_when_no_handle_is_specified
    render_inline(Bali::SortableList::Component.new) do |c|
      c.with_item(update_url: "/items/1") { "Item 1" }
    end
    # Parent should have the CSS class that targets items
    assert_selector('div[class*="[&_.sortable-item]:cursor-grab"]')
  end

  def test_cursor_styling_does_not_add_cursor_grab_to_items_when_handle_is_specified
    render_inline(Bali::SortableList::Component.new(handle: ".handle")) do |c|
      c.with_item(update_url: "/items/1") { "Item 1" }
    end
    # Parent should NOT have the item cursor class
    assert_no_selector('div[class*="[&_.sortable-item]:cursor-grab"]')
    # But should still have the handle cursor class
    assert_selector('div[class*="[&_.handle]:cursor-grab"]')
  end
end

class BaliSortableListItemComponentTest < ComponentTestCase
  def test_base_classes_constant_is_frozen
    assert(Bali::SortableList::Item::Component::BASE_CLASSES.frozen?)
  end

  def test_base_classes_constant_contains_expected_classes
    assert_includes(Bali::SortableList::Item::Component::BASE_CLASSES, "sortable-item")
    assert_includes(Bali::SortableList::Item::Component::BASE_CLASSES, "bg-base-100")
    assert_includes(Bali::SortableList::Item::Component::BASE_CLASSES, "border")
  end
  def test_rendering_renders_an_item_with_update_url
    render_inline(Bali::SortableList::Item::Component.new(update_url: "/items/1")) { "Item content" }
    assert_selector("div.sortable-item")
    assert_selector('div[data-sortable-update-url="/items/1"]')
    assert_text("Item content")
  end

  def test_rendering_sets_item_pull_to_true_by_default
    render_inline(Bali::SortableList::Item::Component.new(update_url: "/items/1"))
    assert_selector('div[data-sortable-item-pull="true"]')
  end

  def test_rendering_allows_disabling_item_pull
    render_inline(Bali::SortableList::Item::Component.new(update_url: "/items/1", item_pull: false))
    assert_selector('div[data-sortable-item-pull="false"]')
  end
  def test_nested_list_slot_renders_with_nested_sortable_list
    render_inline(Bali::SortableList::Item::Component.new(update_url: "/items/1")) do |item|
    item.with_list(list_id: "nested") do |nested|
      nested.with_item(update_url: "/items/nested/1") { "Nested item" }
    end
      "Parent item"
    end
    assert_selector("div.sortable-item div.sortable-list-component")
    assert_text("Parent item")
    assert_text("Nested item")
  end
  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::SortableList::Item::Component.new(update_url: "/items/1", class: "custom-item"))
    assert_selector("div.sortable-item.custom-item")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::SortableList::Item::Component.new(update_url: "/items/1", data: { testid: "item-test" }))
    assert_selector('div[data-testid="item-test"]')
  end
end
