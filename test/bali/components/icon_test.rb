# frozen_string_literal: true

require "test_helper"

class BaliIconComponentTest < ComponentTestCase
  def test_basic_rendering_renders_with_icon_component_class
    # Using a legacy icon that will always exist
    render_inline(Bali::Icon::Component.new("snowflake"))
    assert_selector("span.icon-component")
  end

  def test_basic_rendering_renders_with_custom_id_and_classes
    render_inline(Bali::Icon::Component.new("snowflake", id: "my-icon", class: "text-info"))
    assert_selector("span.icon-component.text-info")
    assert_selector('span[id="my-icon"]')
  end

  def test_sizes_renders_with_small_size_class
    render_inline(Bali::Icon::Component.new("snowflake", size: :small))
    assert_selector("span.icon-component.size-4")
  end

  def test_sizes_renders_with_medium_size_class
    render_inline(Bali::Icon::Component.new("snowflake", size: :medium))
    assert_selector("span.icon-component.size-8")
  end

  def test_sizes_renders_with_large_size_class
    render_inline(Bali::Icon::Component.new("snowflake", size: :large))
    assert_selector("span.icon-component.size-12")
  end

  def test_sizes_numeric_size_renders_inline_style_with_pixel_dimensions
    render_inline(Bali::Icon::Component.new("snowflake", size: 24))
    assert_selector("span.icon-component[style*='width: 24px'][style*='height: 24px']")
    assert_selector("span.icon-component[style*='--bali-icon-size: 24px']")
  end

  def test_sizes_numeric_size_passes_pixel_size_to_lucide_svg
    render_inline(Bali::Icon::Component.new("user", size: 24))
    assert_selector("svg[width='24'][height='24']")
  end

  def test_sizes_numeric_size_drops_named_size_classes
    render_inline(Bali::Icon::Component.new("snowflake", size: 24))
    refute_selector("span.size-4")
    refute_selector("span.size-8")
    refute_selector("span.size-12")
  end

  def test_sizes_numeric_size_preserves_user_supplied_inline_style
    render_inline(Bali::Icon::Component.new("snowflake", size: 24, style: "color: red"))
    assert_selector("span.icon-component[style*='color: red']")
    assert_selector("span.icon-component[style*='--bali-icon-size: 24px']")
  end

  def test_resolution_pipeline_with_lucide_mapped_icons_renders_mapped_icons_through_lucide
    # "user" is mapped to Lucide"s "user' icon
    render_inline(Bali::Icon::Component.new("user"))
    assert_selector("span.icon-component")
    assert_selector("svg")
  end

  def test_resolution_pipeline_with_lucide_mapped_icons_renders_edit_as_pencil_from_lucide
    render_inline(Bali::Icon::Component.new("edit"))
    assert_selector("span.icon-component")
    assert_selector("svg")
  end

  def test_resolution_pipeline_with_kept_icons_brands_renders_brand_icons_from_kept_set
    render_inline(Bali::Icon::Component.new("visa"))
    assert_selector("span.icon-component")
    assert_selector("svg")
  end

  def test_resolution_pipeline_with_kept_icons_brands_renders_social_media_icons_from_kept_set
    render_inline(Bali::Icon::Component.new("whatsapp"))
    assert_selector("span.icon-component")
    assert_selector("svg")
  end

  def test_resolution_pipeline_with_legacy_icons_falls_back_to_legacy_icons_when_not_in_lucide_or_kept
    # "poo" is a legacy icon that might not be mapped
    render_inline(Bali::Icon::Component.new("poo"))
    assert_selector("span.icon-component")
    assert_selector("svg")
  end

  def test_resolution_pipeline_with_invalid_icon_name_raises_iconnotavailable_error
    assert_raises(Bali::Icon::Options::IconNotAvailable) do
      render_inline(Bali::Icon::Component.new("definitely-not-an-icon-xyz"))
    end
  end

  def test_resolution_pipeline_custom_tag_renders_with_custom_tag_name
    render_inline(Bali::Icon::Component.new("snowflake", tag_name: :div))
    assert_selector("div.icon-component")
  end
end
