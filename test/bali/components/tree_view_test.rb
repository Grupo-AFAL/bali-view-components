# frozen_string_literal: true

require "test_helper"

class BaliTreeViewComponentTest < ComponentTestCase
  def setup
    @component = Bali::TreeView::Component.new(current_path: "/")
  end

  def test_basic_rendering_renders_a_tree_container_with_proper_role
    render_inline(@component) do |c|
      c.with_item(name: "Item 1", path: "/items/1")
    end
    assert_selector("ul.tree-view-component")
  end

  def test_basic_rendering_renders_root_items
    render_inline(@component) do |c|
      c.with_item(name: "Item 1", path: "/items/1")
      c.with_item(name: "Item 2", path: "/items/2")
      c.with_item(name: "Item 3", path: "/items/3")
    end
    assert_selector(".tree-view-component")
    assert_selector(".tree-view-item-component .item.is-root", text: "Item 1")
    assert_selector(".tree-view-item-component .item.is-root", text: "Item 2")
    assert_selector(".tree-view-item-component .item.is-root", text: "Item 3")
  end

  def test_basic_rendering_renders_sub_items
    render_inline(@component) do |c|
      c.with_item(name: "Item 1", path: "/items/1") do |sub|
        sub.with_item(name: "Child 1", path: "/items/1a")
      end
    end
    assert_selector(".tree-view-component")
    assert_selector(".children .item", text: "Child 1")
  end

  def test_basic_rendering_renders_empty_tree
    render_inline(@component)
    assert_selector("ul.tree-view-component")
  end

  def test_active_state_marks_the_active_item_with_is_active_class
    render_inline(Bali::TreeView::Component.new(current_path: "/items/1")) do |c|
      c.with_item(name: "Item 1", path: "/items/1")
      c.with_item(name: "Item 2", path: "/items/2")
    end
    assert_selector(".item.is-active", text: "Item 1")
    assert_no_selector(".item.is-active", text: "Item 2")
  end

  def test_active_state_expands_parent_when_child_is_active
    render_inline(Bali::TreeView::Component.new(current_path: "/items/1a")) do |c|
      c.with_item(name: "Item 1", path: "/items/1") do |sub|
        sub.with_item(name: "Child 1", path: "/items/1a")
      end
    end
    assert_selector(".children:not(.hidden)", text: "Child 1")
  end

  def test_childless_items_marks_items_without_children_as_childless
    render_inline(@component) do |c|
      c.with_item(name: "Leaf", path: "/leaf")
    end
    assert_selector(".item.is-childless", text: "Leaf")
  end

  def test_childless_items_does_not_mark_items_with_children_as_childless
    render_inline(@component) do |c|
      c.with_item(name: "Parent", path: "/parent") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_no_selector(".item.is-childless", text: "Parent")
  end

  def test_aria_accessibility_renders_items_as_list_items
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/item")
    end
    assert_selector("li.tree-view-item-component")
  end

  # role="tree" promises roving tabindex, arrow keys and type-ahead. This
  # component implements none of them, so it does not claim the role.
  def test_aria_accessibility_does_not_claim_the_tree_pattern
    render_inline(@component) do |c|
      c.with_item(name: "Parent", path: "/parent") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_no_selector('[role="tree"]')
    assert_no_selector('[role="treeitem"]')
    assert_no_selector('[role="group"]')
  end

  def test_aria_accessibility_sets_aria_expanded_on_the_caret_of_items_with_children
    render_inline(Bali::TreeView::Component.new(current_path: "/parent")) do |c|
      c.with_item(name: "Parent", path: "/parent") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_selector('button.caret[aria-expanded="true"]')
  end

  def test_aria_accessibility_points_the_caret_at_the_children_it_discloses
    render_inline(@component) do |c|
      c.with_item(name: "Parent", path: "/parent") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    controls = page.find("button.caret")["aria-controls"]
    refute_nil(controls)
    assert_selector("ul.children##{controls}")
  end

  def test_aria_accessibility_names_the_caret_after_the_branch_it_toggles
    render_inline(@component) do |c|
      c.with_item(name: "Parent", path: "/parent") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_selector('button.caret[aria-label="Toggle Parent"]')
  end

  # An invisible button would still be a tab stop and still be announced.
  def test_aria_accessibility_renders_an_inert_spacer_instead_of_a_caret_for_childless_items
    render_inline(@component) do |c|
      c.with_item(name: "Leaf", path: "/leaf")
    end
    assert_no_selector("button.caret")
    assert_selector('span.caret[aria-hidden="true"]')
  end

  def test_aria_accessibility_nests_children_in_a_list
    render_inline(@component) do |c|
      c.with_item(name: "Parent", path: "/parent") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_selector("ul.children")
  end

  # NOTE: ViewComponent's renders_many with lambdas only supports 2 levels of nesting.
  # Three-level deep nesting requires a different architectural approach.
  def test_nested_levels_renders_two_levels_deep_when_nested_item_is_active
    render_inline(Bali::TreeView::Component.new(current_path: "/l1/l2")) do |c|
      c.with_item(name: "Level 1", path: "/l1") do |l1|
        l1.with_item(name: "Level 2", path: "/l1/l2")
      end
    end
    # Level 2 is active, so parent children container should be expanded
    assert_selector(".children:not(.hidden) .item.is-active", text: "Level 2")
  end

  def test_nested_levels_renders_collapsed_nested_items_when_not_active
    render_inline(Bali::TreeView::Component.new(current_path: "/other")) do |c|
      c.with_item(name: "Level 1", path: "/l1") do |l1|
        l1.with_item(name: "Level 2", path: "/l1/l2")
      end
    end
    # Children should be hidden when not active
    assert_selector(".children.hidden")
  end

  def test_stimulus_integration_sets_up_tree_view_item_controller
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/item")
    end
    assert_selector('[data-controller="tree-view-item"]')
  end

  def test_stimulus_integration_sets_url_value_for_navigation
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/custom/path")
    end
    assert_selector('[data-tree-view-item-url-value="/custom/path"]')
  end

  def test_stimulus_integration_sets_caret_target_on_items_with_children
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/item") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_selector('[data-tree-view-item-target="caret"]')
  end

  def test_stimulus_integration_sets_children_target
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/item") do |sub|
        sub.with_item(name: "Child", path: "/child")
      end
    end
    assert_selector('[data-tree-view-item-target="children"]')
  end

  def test_custom_options_accepts_custom_class_on_tree_container
    render_inline(Bali::TreeView::Component.new(current_path: "/", class: "custom-tree")) do |c|
      c.with_item(name: "Item", path: "/item")
    end
    assert_selector(".tree-view-component.custom-tree")
  end

  def test_custom_options_accepts_custom_class_on_items
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/item", class: "custom-item")
    end
    assert_selector(".tree-view-item-component.custom-item")
  end

  def test_custom_options_accepts_custom_data_attributes_on_items
    render_inline(@component) do |c|
      c.with_item(name: "Item", path: "/item", data: { testid: "my-item" })
    end
    assert_selector('[data-testid="my-item"]')
  end
end

class BaliTreeViewItemComponentTest < ComponentTestCase
  def test_constants_has_base_classes_constant
    assert_equal("tree-view-item-component", Bali::TreeView::Item::Component::BASE_CLASSES)
  end

  def test_constants_has_controller_name_constant
    assert_equal("tree-view-item", Bali::TreeView::Item::Component::CONTROLLER_NAME)
  end

  def test_constants_has_frozen_item_classes_constant
    assert(Bali::TreeView::Item::Component::ITEM_CLASSES.frozen?)
  end

  def test_constants_has_frozen_caret_classes_constant
    assert(Bali::TreeView::Item::Component::CARET_CLASSES.frozen?)
  end
end
