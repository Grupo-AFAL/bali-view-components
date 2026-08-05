# frozen_string_literal: true

require "test_helper"

class BaliIconComponentTest < ComponentTestCase
  def test_basic_rendering_renders_with_icon_component_class
    # "snowflake" is an old Bali name Lucide covers under the same name
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

  def test_resolution_pipeline_with_legacy_only_name_raises_instead_of_falling_back
    # "money-bill-wave" shipped as a legacy SVG and is neither mapped nor kept
    error = assert_raises(Bali::Icon::Options::IconNotAvailable) do
      render_inline(Bali::Icon::Component.new("money-bill-wave"))
    end
    assert_includes(error.message, "money-bill-wave")
  end

  def test_resolution_pipeline_with_snake_case_spelling_raises_and_suggests_the_dashed_name
    error = assert_raises(Bali::Icon::Options::IconNotAvailable) do
      render_inline(Bali::Icon::Component.new("arrow_left"))
    end
    assert_includes(error.message, "arrow-left")
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

  # #685: an icon is decorative unless its host says otherwise. Lucide already
  # hides its own `<svg>`; the kept, custom and legacy sources do not, so the
  # attribute goes on the wrapper where it covers all four.
  def test_accessibility_hides_the_icon_from_assistive_tech_by_default
    render_inline(Bali::Icon::Component.new("snowflake"))
    assert_selector("span.icon-component[aria-hidden='true']", visible: :all)
  end

  def test_accessibility_hides_kept_icons_whose_svg_carries_no_aria_hidden
    render_inline(Bali::Icon::Component.new("visa"))
    assert_selector("span.icon-component[aria-hidden='true']", visible: :all)
  end

  def test_accessibility_can_be_exposed_explicitly
    render_inline(Bali::Icon::Component.new("snowflake", "aria-hidden": false))
    assert_selector("span.icon-component[aria-hidden='false']", visible: :all)
  end
end
