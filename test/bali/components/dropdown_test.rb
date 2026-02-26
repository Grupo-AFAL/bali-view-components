# frozen_string_literal: true

require "test_helper"

class BaliDropdownComponentTest < ComponentTestCase
  def setup
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item 1" }
      c.with_item(href: "#") { "Item 2" }
    end
  end

  def test_renders_dropdown_container_with_daisyui_classes
    assert_selector(".dropdown")
  end

  def test_renders_trigger_button
    assert_selector(".btn", text: "Trigger")
  end

  def test_renders_dropdown_content_with_menu_class
    assert_selector(".dropdown-content.menu")
  end

  def test_renders_items_in_list_format
    assert_selector("li", count: 2)
  end

  def test_alignments_defaults_to_right_alignment_with_dropdown_end
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-end")
  end

  def test_alignments_renders_left_alignment_without_position_class
    render_inline(Bali::Dropdown::Component.new(align: :left)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown")
    assert_no_selector(".dropdown-end")
  end

  def test_alignments_renders_top_alignment
    render_inline(Bali::Dropdown::Component.new(align: :top)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-top")
  end

  def test_alignments_renders_bottom_end_alignment
    render_inline(Bali::Dropdown::Component.new(align: :bottom_end)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-bottom.dropdown-end")
  end

  def test_hoverable_adds_dropdown_hover_class_when_hoverable
    render_inline(Bali::Dropdown::Component.new(hoverable: true)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-hover")
  end

  def test_hoverable_does_not_add_controller_when_hoverable_css_only
    render_inline(Bali::Dropdown::Component.new(hoverable: true)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_no_selector('[data-controller="dropdown"]')
  end

  def test_wide_option_uses_w_80_class_for_wide_dropdowns
    render_inline(Bali::Dropdown::Component.new(wide: true)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown-content.w-80")
  end

  def test_wide_option_uses_w_52_class_for_normal_dropdowns
    render_inline(Bali::Dropdown::Component.new(wide: false)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown-content.w-52")
  end

  def test_custom_content_renders_custom_html_content
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.tag.li { c.tag.span("Custom content", class: "custom-class") }
    end
    assert_selector("li span.custom-class", text: "Custom content")
  end

  def test_trigger_component_renders_with_tabindex_for_focus_behavior
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('[tabindex="0"]', text: "Trigger")
  end

  def test_trigger_component_renders_with_role_button_for_accessibility
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('[role="button"]', text: "Trigger")
  end

  def test_trigger_component_supports_icon_variant
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :icon) { "Icon" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".btn.btn-ghost.btn-circle", text: "Icon")
  end

  def test_trigger_component_supports_ghost_variant
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :ghost) { "Ghost" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".btn.btn-ghost", text: "Ghost")
  end

  def test_trigger_component_supports_custom_variant_with_no_btn_class
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :custom, class: "my-custom-class") { "Custom" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".my-custom-class", text: "Custom")
    assert_no_selector(".btn", text: "Custom")
  end

  def test_accessibility_renders_menu_with_aria_label
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('ul[role="menu"][aria-label="Dropdown menu"]')
  end

  def test_accessibility_renders_items_with_proper_roles
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item 1" }
      c.with_item(href: "#") { "Item 2" }
    end
    assert_selector('li[role="none"]', count: 2)
    assert_selector('a[role="menuitem"]', count: 2)
  end

  def test_accessibility_renders_trigger_with_aria_haspopup_and_aria_expanded
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('[aria-haspopup="true"][aria-expanded="false"]', text: "Trigger")
  end
end
