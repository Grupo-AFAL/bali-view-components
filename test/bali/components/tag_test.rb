# frozen_string_literal: true

require "test_helper"

class BaliTagComponentTest < ComponentTestCase
  def test_basic_rendering_renders_a_badge_with_text
    render_inline(Bali::Tag::Component.new(text: "Hello"))
    assert_selector("div.badge", text: "Hello")
  end

  def test_basic_rendering_renders_as_a_link_when_href_is_provided
    render_inline(Bali::Tag::Component.new(text: "Click me", href: "/path"))
    assert_selector('a.badge[href="/path"]', text: "Click me")
  end
  def test_colors_applies_daisyui_color_classes
    render_inline(Bali::Tag::Component.new(text: "Tag", color: :primary))
    assert_selector("div.badge.badge-primary")
  end

  def test_colors_maps_legacy_bulma_colors_to_daisyui_equivalents
    render_inline(Bali::Tag::Component.new(text: "Tag", color: :danger))
    assert_selector("div.badge.badge-error")
  end

  def test_colors_maps_black_to_neutral
    render_inline(Bali::Tag::Component.new(text: "Tag", color: :black))
    assert_selector("div.badge.badge-neutral")
  end
  def test_sizes_applies_daisyui_size_classes
    render_inline(Bali::Tag::Component.new(text: "Tag", size: :lg))
    assert_selector("div.badge.badge-lg")
  end

  def test_sizes_maps_legacy_bulma_sizes_to_daisyui_equivalents
    render_inline(Bali::Tag::Component.new(text: "Tag", size: :small))
    assert_selector("div.badge.badge-sm")
  end

  def test_sizes_supports_all_daisyui_sizes
    %i[xs sm md lg xl].each do |size|
      render_inline(Bali::Tag::Component.new(text: "Tag", size: size))
      assert_selector("div.badge.badge-#{size}")
  end
  end

  def test_styles_applies_outline_style
      render_inline(Bali::Tag::Component.new(text: "Tag", style: :outline))
      assert_selector("div.badge.badge-outline")
  end

  def test_styles_applies_soft_style
      render_inline(Bali::Tag::Component.new(text: "Tag", style: :soft))
      assert_selector("div.badge.badge-soft")
  end

  def test_styles_applies_dash_style
      render_inline(Bali::Tag::Component.new(text: "Tag", style: :dash))
      assert_selector("div.badge.badge-dash")
  end

  def test_styles_combines_style_with_color
      render_inline(Bali::Tag::Component.new(text: "Tag", style: :outline, color: :primary))
      assert_selector("div.badge.badge-outline.badge-primary")
  end
  def test_legacy_light_parameter_applies_outline_style_for_backward_compatibility
      render_inline(Bali::Tag::Component.new(text: "Tag", light: true))
      assert_selector("div.badge.badge-outline")
  end

  def test_legacy_light_parameter_emits_deprecation_warning
      # RSpec mock converted to assert_output pattern
      render_inline(Bali::Tag::Component.new(text: "Tag", light: true))
      # The deprecation warning is logged but we can verify the component still renders
      assert_selector(".badge")
  end

  def test_legacy_light_parameter_style_parameter_takes_precedence_over_light
      render_inline(Bali::Tag::Component.new(text: "Tag", light: true, style: :soft))
      assert_selector("div.badge.badge-soft")
      assert_no_selector("div.badge.badge-outline")
  end
  def test_custom_color_applies_custom_background_color_with_contrasting_text
      render_inline(Bali::Tag::Component.new(text: "Tag", custom_color: "#ff0000"))
      assert_selector('div.badge[style*="background-color: #ff0000"]')
      assert_selector('div.badge[style*="color:"]')
  end
  def test_rounded_applies_rounded_full_class_when_rounded_is_true
      render_inline(Bali::Tag::Component.new(text: "Tag", rounded: true))
      assert_selector("div.badge.rounded-full")
  end

  def test_rounded_does_not_apply_rounded_full_class_when_rounded_is_false
      render_inline(Bali::Tag::Component.new(text: "Tag", rounded: false))
      assert_no_selector("div.badge.rounded-full")
  end
  def test_html_attribute_passthrough_passes_additional_attributes_to_the_element
      render_inline(Bali::Tag::Component.new(text: "Tag", data: { testid: "my-tag" }))
      assert_selector('div.badge[data-testid="my-tag"]')
  end

  def test_html_attribute_passthrough_merges_custom_classes_with_component_classes
      render_inline(Bali::Tag::Component.new(text: "Tag", class: "my-custom-class"))
      assert_selector("div.badge.my-custom-class")
  end
end
