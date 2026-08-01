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

  # The hook `app/components/bali/tag/index.css` styles. Losing it takes the
  # nowrap of #655 with it, and nothing else in the markup would change.
  def test_basic_rendering_carries_the_tag_component_css_hook
    render_inline(Bali::Tag::Component.new(text: "Hello"))
    assert_selector("div.badge.tag-component")
  end

  def test_colors_applies_daisyui_color_classes
    render_inline(Bali::Tag::Component.new(text: "Tag", color: :primary))
    assert_selector("div.badge.badge-primary")
  end

  def test_colors_accepts_a_string
    render_inline(Bali::Tag::Component.new(text: "Tag", color: "primary"))
    assert_selector("div.badge.badge-primary")
  end

  def test_colors_rejects_a_removed_bulma_name_and_names_the_replacement
    error = assert_raises(ArgumentError) do
      Bali::Tag::Component.new(text: "Tag", color: :danger)
    end
    assert_includes error.message, "color :danger"
    assert_includes error.message, "color: :error"
  end

  def test_colors_rejects_every_removed_bulma_name
    { danger: ":error", link: ":primary", black: ":neutral", dark: ":neutral",
      light: ":ghost", white: ":ghost" }.each do |removed, replacement|
      error = assert_raises(ArgumentError) do
        Bali::Tag::Component.new(text: "Tag", color: removed)
      end
      assert_includes error.message, "color: #{replacement}"
    end
  end

  def test_colors_rejects_an_unknown_name_and_lists_the_valid_ones
    error = assert_raises(ArgumentError) do
      Bali::Tag::Component.new(text: "Tag", color: :fuchsia)
    end
    assert_includes error.message, "unknown color :fuchsia"
    assert_includes error.message, ":primary"
  end

  def test_sizes_applies_daisyui_size_classes
    render_inline(Bali::Tag::Component.new(text: "Tag", size: :lg))
    assert_selector("div.badge.badge-lg")
  end

  def test_sizes_supports_all_daisyui_sizes
    %i[xs sm md lg xl].each do |size|
      render_inline(Bali::Tag::Component.new(text: "Tag", size: size))
      assert_selector("div.badge.badge-#{size}")
    end
  end

  def test_sizes_rejects_a_removed_bulma_name_and_names_the_replacement
    { small: ":sm", medium: ":md", large: ":lg", normal: ":md" }.each do |removed, replacement|
      error = assert_raises(ArgumentError) do
        Bali::Tag::Component.new(text: "Tag", size: removed)
      end
      assert_includes error.message, "size #{removed.inspect}"
      assert_includes error.message, "size: #{replacement}"
    end
  end

  def test_sizes_rejects_an_unknown_name
    error = assert_raises(ArgumentError) do
      Bali::Tag::Component.new(text: "Tag", size: :huge)
    end
    assert_includes error.message, "unknown size :huge"
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

  # Without this it lands in **options and renders as a `light="true"`
  # attribute, which is exactly the silent no-op the removal is undoing.
  def test_light_is_rejected_and_names_its_replacement
    error = assert_raises(ArgumentError) do
      Bali::Tag::Component.new(text: "Tag", light: true)
    end
    assert_includes error.message, "no longer accepts `light:`"
    assert_includes error.message, "style: :outline"
  end

  def test_light_is_rejected_even_when_false
    assert_raises(ArgumentError) { Bali::Tag::Component.new(text: "Tag", light: false) }
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
