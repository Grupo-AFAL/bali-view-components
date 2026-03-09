# frozen_string_literal: true

require "test_helper"

class BaliLinkComponentTest < ComponentTestCase
  def test_default_renders_a_basic_link
    render_inline(Bali::Link::Component.new(name: "Click me!", href: "#"))
    assert_selector("a", text: "Click me!")
    assert_selector('a[href="#"]')
  end

  def test_default_renders_with_daisyui_link_class
    render_inline(Bali::Link::Component.new(name: "Click me!", href: "#"))
    assert_selector("a.link")
  end

  def test_default_includes_inline_flex_for_icon_alignment
    render_inline(Bali::Link::Component.new(name: "Click me!", href: "#"))
    assert_selector("a.inline-flex")
  end
  Bali::Link::Component::VARIANTS.each_key do |variant|
    define_method("test_variants_renders_#{variant}_variant") do
      render_inline(Bali::Link::Component.new(name: "Click", href: "#", variant: variant))
      assert_selector("a.btn.#{Bali::Link::Component::VARIANTS[variant]}", text: "Click")
      assert_selector('a[href="#"]')
    end
  end

  def test_sizes_renders_small_button
    render_inline(Bali::Link::Component.new(name: "Small", href: "#", variant: :primary, size: :sm))
    assert_selector("a.btn.btn-sm")
  end

  def test_sizes_renders_large_button
    render_inline(Bali::Link::Component.new(name: "Large", href: "#", variant: :primary, size: :lg))
    assert_selector("a.btn.btn-lg")
  end

  def test_sizes_ignores_size_without_variant
    render_inline(Bali::Link::Component.new(name: "Link", href: "#", size: :lg))
    assert_no_selector("a.btn-lg")
    assert_selector("a.link")
  end

  def test_styles_renders_outline_style
    render_inline(Bali::Link::Component.new(name: "Outline", href: "#", variant: :primary, style: :outline))
    assert_selector("a.btn.btn-primary.btn-outline")
  end

  def test_styles_renders_soft_style
    render_inline(Bali::Link::Component.new(name: "Soft", href: "#", variant: :primary, style: :soft))
    assert_selector("a.btn.btn-primary.btn-soft")
  end

  def test_styles_applies_style_as_button_when_used_without_variant
    render_inline(Bali::Link::Component.new(name: "Outline", href: "#", style: :outline))
    assert_selector("a.btn.btn-outline")
    assert_no_selector("a.link")
  end

  def test_styles_combines_style_with_size
    render_inline(Bali::Link::Component.new(name: "Small Outline", href: "#", variant: :primary, style: :outline, size: :sm))
    assert_selector("a.btn.btn-primary.btn-outline.btn-sm")
  end

  def test_with_icon_slot_renders_icon_via_slot
    render_inline(Bali::Link::Component.new(name: "Click", href: "#")) do |c|
      c.with_icon("star")
    end
    assert_selector("a", text: "Click")
    assert_selector("span.icon-component")
  end

  def test_with_icon_slot_renders_icon_with_button_variant
    render_inline(Bali::Link::Component.new(name: "Click", href: "#", variant: :primary)) do |c|
      c.with_icon("star")
    end
    assert_selector("a.btn", text: "Click")
    assert_selector("span.icon-component")
  end

  def test_with_icon_name_parameter_renders_icon_from_icon_name
    render_inline(Bali::Link::Component.new(name: "Click", href: "#", icon_name: "star"))
    assert_selector("span.icon-component")
  end

  def test_with_icon_right_slot_renders_icon_on_the_right
    render_inline(Bali::Link::Component.new(name: "Next", href: "#", variant: :primary)) do |c|
      c.with_icon_right("chevron-right")
    end
    assert_selector("a.btn", text: "Next")
    assert_selector("span.icon-component")
  end

  def test_active_indicator_when_current_path_is_active_does_not_add_the_active_class_when_active_is_false
    render_inline(Bali::Link::Component.new(name: "Link", href: "/items", active_path: "/items", active: false))
    assert_no_selector("a.active")
  end

  def test_active_indicator_when_current_path_is_active_adds_the_active_class_when_active_is_true
    render_inline(Bali::Link::Component.new(name: "Link", href: "/items", active_path: "/items", active: true))
    assert_selector("a.active")
  end

  def test_active_indicator_when_current_path_is_active_adds_the_active_class_when_active_is_nil_auto_detect
    render_inline(Bali::Link::Component.new(name: "Link", href: "/items", active_path: "/items"))
    assert_selector("a.active")
  end

  def test_active_indicator_when_current_path_is_not_active_adds_the_active_class_when_active_is_true_forced
    render_inline(Bali::Link::Component.new(name: "Link", href: "/items", active_path: "/movies", active: true))
    assert_selector("a.active")
  end

  def test_active_indicator_when_current_path_is_not_active_does_not_add_the_active_class_when_active_is_false
    render_inline(Bali::Link::Component.new(name: "Link", href: "/items", active_path: "/movies", active: false))
    assert_no_selector("a.active")
  end

  def test_active_indicator_when_current_path_is_not_active_does_not_add_the_active_class_when_active_is_nil_auto_detect
    render_inline(Bali::Link::Component.new(name: "Link", href: "/items", active_path: "/movies"))
    assert_no_selector("a.active")
  end

  def test_method_parameter_renders_turbo_method_for_non_get_requests
    render_inline(Bali::Link::Component.new(name: "Delete", href: "#", method: :post))
    assert_selector('a[data-turbo-method="post"]', text: "Delete")
  end

  def test_method_parameter_renders_data_method_for_get_requests
    render_inline(Bali::Link::Component.new(name: "Fetch", href: "#", method: :get))
    assert_selector("a.link", text: "Fetch")
    assert_no_selector('a[data-turbo-method="get"]')
    assert_selector('a[data-method="get"]')
  end

  def test_disabled_adds_btn_disabled_class_when_disabled_with_variant
    render_inline(Bali::Link::Component.new(name: "Disabled", href: "/", variant: :primary, disabled: true))
    assert_selector("a.btn-disabled")
    assert_no_selector("a[href]")
  end

  def test_disabled_does_not_add_btn_disabled_class_for_plain_disabled_link
    render_inline(Bali::Link::Component.new(name: "Disabled", href: "/", disabled: true))
    assert_no_selector("a.btn-disabled")
    assert_no_selector("a[href]")
  end

  def test_plain_mode_renders_with_flex_classes_for_menu_items
    render_inline(Bali::Link::Component.new(name: "Menu Item", href: "#", plain: true))
    assert_selector("a.flex.items-center.gap-2")
    assert_no_selector("a.link")
  end

  def test_authorization_renders_when_authorized
    render_inline(Bali::Link::Component.new(name: "Link", href: "#", authorized: true))
    assert_selector("a", text: "Link")
  end

  def test_authorization_does_not_render_when_not_authorized
    render_inline(Bali::Link::Component.new(name: "Link", href: "#", authorized: false))
    assert_no_selector("a")
  end

  def test_custom_options_passthrough_accepts_custom_classes
    render_inline(Bali::Link::Component.new(name: "Link", href: "#", class: "custom-class"))
    assert_selector("a.custom-class")
  end

  def test_custom_options_passthrough_accepts_data_attributes
    render_inline(Bali::Link::Component.new(name: "Link", href: "#", data: { testid: "test-link" }))
    assert_selector('a[data-testid="test-link"]')
  end

  def test_custom_options_passthrough_accepts_id_attribute
    render_inline(Bali::Link::Component.new(name: "Link", href: "#", id: "my-link"))
    assert_selector("a#my-link")
  end

  def test_content_block_renders_custom_content
    render_inline(Bali::Link::Component.new(href: "#", variant: :primary)) do
      "Custom Content"
    end
    assert_selector("a.btn", text: "Custom Content")
  end

  def test_deprecated_type_parameter_supports_type_for_backwards_compatibility
    render_inline(Bali::Link::Component.new(name: "Button", href: "#", type: :primary))
    assert_selector("a.btn.btn-primary", text: "Button")
  end

  def test_deprecated_type_parameter_prefers_variant_over_type_when_both_are_provided
    render_inline(Bali::Link::Component.new(name: "Button", href: "#", variant: :error, type: :primary))
    assert_selector("a.btn.btn-error", text: "Button")
    assert_no_selector("a.btn-primary")
  end

  # Responsive (icon-only on mobile)

  def test_responsive_adds_btn_square_class_with_icon_and_variant
    render_inline(Bali::Link::Component.new(name: "New", href: "#", variant: :primary, icon_name: "plus"))
    assert_selector("a.btn.max-sm\\:btn-square")
  end

  def test_responsive_wraps_name_in_hidden_span
    render_inline(Bali::Link::Component.new(name: "New", href: "#", variant: :primary, icon_name: "plus"))
    assert_selector("a span.max-sm\\:hidden", text: "New")
  end

  def test_responsive_adds_aria_label
    render_inline(Bali::Link::Component.new(name: "New", href: "#", variant: :primary, icon_name: "plus"))
    assert_selector('a[aria-label="New"]')
  end

  def test_responsive_false_renders_normally
    render_inline(Bali::Link::Component.new(name: "New", href: "#", variant: :primary, icon_name: "plus", responsive: false))
    assert_no_selector("a.max-sm\\:btn-square")
    assert_no_selector("a span.max-sm\\:hidden")
    assert_no_selector("a[aria-label]")
  end

  def test_responsive_without_icon_does_not_add_btn_square
    render_inline(Bali::Link::Component.new(name: "New", href: "#", variant: :primary))
    assert_no_selector("a.max-sm\\:btn-square")
  end

  def test_responsive_without_variant_does_not_add_btn_square
    render_inline(Bali::Link::Component.new(name: "New", href: "#", icon_name: "plus"))
    assert_no_selector("a.max-sm\\:btn-square")
  end
end
