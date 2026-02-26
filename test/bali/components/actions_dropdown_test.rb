# frozen_string_literal: true

require "test_helper"

class BaliActionsDropdownComponentTest < ComponentTestCase
  #

  def test_basic_rendering_renders_dropdown_component_with_daisyui_classes
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-start")
  end

  def test_basic_rendering_renders_with_daisyui_btn_classes_on_trigger
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector(".btn.btn-ghost.btn-sm.btn-circle")
  end

  def test_basic_rendering_renders_dropdown_content_menu
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("ul.dropdown-content.menu")
    assert_selector("ul.dropdown-content li a", text: "Edit")
  end

  def test_basic_rendering_renders_items_inside_li_elements
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#edit")
    c.with_item(name: "Delete", href: "#delete", method: :delete)
    end
    assert_selector("ul.menu li", count: 2)
  end

  def test_basic_rendering_applies_custom_classes_via_options
    render_inline(Bali::ActionsDropdown::Component.new(class: "my-custom-class")) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.my-custom-class")
  end

  def test_basic_rendering_renders_default_ellipsis_h_icon
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('button[type="button"] svg')
  end
  #

  def test_custom_icon_allows_changing_the_trigger_icon
    render_inline(Bali::ActionsDropdown::Component.new(icon: "more")) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('button[type="button"] svg')
  end
  #

  def test_custom_trigger_renders_custom_trigger_when_provided
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_trigger do
    '<button class="custom-trigger">Actions</button>'.html_safe
    end
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("button.custom-trigger", text: "Actions")
    assert_no_selector("button.btn-circle")
  end
  #

  def test_accessibility_uses_semantic_button_element_for_trigger
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('button[type="button"][aria-haspopup="true"]')
  end
  #

  def test_custom_content_fallback_renders_block_content_when_no_items_provided
    render_inline(Bali::ActionsDropdown::Component.new) do
    '<li><a href="#">Custom Link</a></li>'.html_safe
    end
    assert_selector("ul.menu li a", text: "Custom Link")
  end
  #

  def test_render_behavior_does_not_render_when_no_items_and_no_content
    result = render_inline(Bali::ActionsDropdown::Component.new)
    assert_empty(result.to_html)
  end

  def test_render_behavior_renders_when_content_is_provided_without_items
    render_inline(Bali::ActionsDropdown::Component.new) do
    "<li>Content</li>".html_safe
    end
    assert_selector("div.dropdown")
  end
  #

  def test_horizontal_alignment_supports_align_start_default
    render_inline(Bali::ActionsDropdown::Component.new(align: :start)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-start")
  end

  def test_horizontal_alignment_supports_align_center
    render_inline(Bali::ActionsDropdown::Component.new(align: :center)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-center")
  end

  def test_horizontal_alignment_supports_align_end
    render_inline(Bali::ActionsDropdown::Component.new(align: :end)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-end")
  end
  #

  def test_vertical_direction_supports_direction_top
    render_inline(Bali::ActionsDropdown::Component.new(direction: :top)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-top")
  end

  def test_vertical_direction_supports_direction_bottom
    render_inline(Bali::ActionsDropdown::Component.new(direction: :bottom)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-bottom")
  end

  def test_vertical_direction_supports_direction_left
    render_inline(Bali::ActionsDropdown::Component.new(direction: :left)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-left")
  end

  def test_vertical_direction_supports_direction_right
    render_inline(Bali::ActionsDropdown::Component.new(direction: :right)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-right")
  end
  #

  def test_combined_positions_supports_direction_and_alignment_together
    render_inline(Bali::ActionsDropdown::Component.new(direction: :top, align: :end)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-top.dropdown-end")
  end
  #

  def test_menu_width_uses_medium_width_by_default
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("ul.dropdown-content.w-52")
  end

  def test_menu_width_supports_small_width
    render_inline(Bali::ActionsDropdown::Component.new(width: :sm)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("ul.dropdown-content.w-40")
  end

  def test_menu_width_supports_large_width
    render_inline(Bali::ActionsDropdown::Component.new(width: :lg)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("ul.dropdown-content.w-64")
  end

  def test_menu_width_supports_extra_large_width
    render_inline(Bali::ActionsDropdown::Component.new(width: :xl)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector("ul.dropdown-content.w-80")
  end
  #

  def test_popover_mode_renders_hovercard_component_when_popover_true
    render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('.hover-card-component[data-controller="hovercard"]')
  end

  def test_popover_mode_uses_click_trigger_in_popover_mode
    render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-hovercard-trigger-value="click"]')
  end

  def test_popover_mode_appends_to_body_in_popover_mode
    render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-hovercard-append-to-value="body"]')
  end

  def test_popover_mode_does_not_show_arrow_in_popover_mode
    render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-hovercard-arrow-value="false"]')
  end

  def test_popover_mode_renders_menu_inside_template_for_tippy
    result = render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_includes(result.to_html, 'data-hovercard-target="template"')
    assert_includes(result.to_html, "ul")
    assert_includes(result.to_html, "menu")
  end

  def test_popover_mode_renders_items_correctly_in_popover_mode
    result = render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#edit")
    c.with_item(name: "Delete", href: "#delete", method: :delete)
    end
    assert_equal(2, result.to_html.scan("<li>").count)
  end

  def test_popover_mode_does_not_render_css_dropdown_wrapper_in_popover_mode
    render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_item(name: "Edit", href: "#")
    end
    assert_no_selector("div.dropdown")
  end

  def test_popover_mode_maps_direction_and_align_to_tippy_placement
    component = Bali::ActionsDropdown::Component.new(popover: true, direction: :top, align: :end)
    assert_equal("top-end", component.tippy_placement)
  end

  def test_popover_mode_defaults_placement_to_bottom_start
    component = Bali::ActionsDropdown::Component.new(popover: true)
    assert_equal("bottom-start", component.tippy_placement)
  end

  def test_popover_mode_supports_custom_trigger_in_popover_mode
    render_inline(Bali::ActionsDropdown::Component.new(popover: true)) do |c|
    c.with_trigger do
    '<button class="custom-trigger">Actions</button>'.html_safe
    end
    c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-hovercard-target="trigger"] button.custom-trigger', text: "Actions")
  end
end
