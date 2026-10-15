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

  # In rem, like the 1rem default in bali/general.css: a root font-size other than 16px
  # moves them together.
  def test_sizes_named_sizes_set_the_size_variable_in_rem
    { small: 1, medium: 2, large: 3 }.each do |size, rem|
      render_inline(Bali::Icon::Component.new("snowflake", size: size))
      assert_selector("span.icon-component[style='--bali-icon-size: #{rem}rem']")
    end
  end

  # Raises in 4.0. Until then it draws the default, which is what it always drew.
  def test_sizes_unknown_key_warns_and_renders_the_default
    assert_deprecated(/Bali::Icon\(size: :sm\).*Valid: :small, :medium, :large/, Bali.deprecator) do
      render_inline(Bali::Icon::Component.new("snowflake", size: :sm))
    end
    assert_selector("span.icon-component:not([style])")
  end

  # #1424: an inline `width`/`height` would outrank a caller's `size-*` class.
  # That the class wins is measured in cypress/e2e/icon-size.cy.js.
  def test_sizes_numeric_size_sets_only_the_size_variable
    render_inline(Bali::Icon::Component.new("snowflake", size: 24))
    assert_selector("span.icon-component[style='--bali-icon-size: 24px']")
  end

  # Deliberately NOT 24: Lucide's default is 24, so a 24px fixture passes even
  # when the override is silently discarded — which is exactly how #986 hid.
  def test_sizes_numeric_size_passes_pixel_size_to_lucide_svg
    render_inline(Bali::Icon::Component.new("user", size: 32))
    assert_selector("svg[width='32'][height='32']")
  end

  # #986: `LucideRails.default_options` carries "width"/"height" as String keys
  # and the Symbol overrides serialized as a second pair; HTML parsers keep the
  # first, so every SVG came out 24x24 outside Bali's CSS. Nokogiri also drops
  # the duplicate, so this asserts on the raw rendered string.
  def test_sizes_svg_carries_a_single_width_height_pair
    render_inline(Bali::Icon::Component.new("user", size: 32))
    # Lookbehind: `stroke-width="2"` is not a width attribute.
    assert_equal(1, rendered_content.scan(/(?<!-)width="/).size)
    assert_equal(1, rendered_content.scan(/(?<!-)height="/).size)
    refute_match(/(?<!-)width="24"/, rendered_content)
  end

  # #1424: a size utility on the wrapper ties with the caller's in @layer utilities,
  # and the order Tailwind emits them in, not the caller, picks the winner.
  def test_sizes_the_wrapper_carries_no_size_utility
    [ nil, :medium, 24 ].each do |size|
      render_inline(Bali::Icon::Component.new("snowflake", size: size))
      refute_match(/(^|\s)(\*:)?(size|w|h)-/, page.find("span.icon-component")[:class])
    end
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

  # #987: the mapping's key is dashed now, so the underscored accident raises
  # and the suggestion points at the spelling the migration guide recommends —
  # not the other way around, which is what the v1-leftover key produced.
  def test_resolution_pipeline_question_circle_resolves_and_the_underscored_form_suggests_it
    render_inline(Bali::Icon::Component.new("question-circle"))
    assert_selector("svg.lucide-icon")

    error = assert_raises(Bali::Icon::Options::IconNotAvailable) do
      render_inline(Bali::Icon::Component.new("question_circle"))
    end
    assert_includes(error.message, "question-circle")
  end

  # #985: suggestions rank the exact (dash/underscore-normalized) match first,
  # so `panel_left` cannot lose `panel-left` itself to `layout-panel-left`
  # when `first(3)` truncates.
  def test_resolution_pipeline_suggestions_rank_the_exact_match_first
    error = assert_raises(Bali::Icon::Options::IconNotAvailable) do
      render_inline(Bali::Icon::Component.new("panel_left"))
    end
    assert_match(/Did you mean: panel-left(,|\?)/, error.message)
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

  def test_cache_builds_a_lucide_svg_once_per_name_and_size
    with_empty_lucide_cache do
      render_inline(Bali::Icon::Component.new("edit", size: 32))
      assert_equal([ [ "pencil", 32 ] ], lucide_svgs.keys)

      lucide_svgs[[ "pencil", 32 ]] = "<svg>reused</svg>"
      render_inline(Bali::Icon::Component.new("pencil", size: 32))
      assert_includes(rendered_content, "<svg>reused</svg>")

      render_inline(Bali::Icon::Component.new("pencil"))
      refute_includes(rendered_content, "reused")
    end
  end

  # `Bali.add_icon` can change a kept or custom icon at runtime; an unknown name has no <svg>.
  def test_cache_keeps_only_lucide_icons
    with_empty_lucide_cache do
      previous = Bali.custom_icons
      Bali.custom_icons = previous.merge("cache-custom" => "<svg></svg>")
      render_inline(Bali::Icon::Component.new("visa"))
      render_inline(Bali::Icon::Component.new("cache-custom"))
      assert_raises(Bali::Icon::Options::IconNotAvailable) do
        render_inline(Bali::Icon::Component.new("definitely-not-an-icon-xyz"))
      end

      assert_empty(lucide_svgs.keys)
    ensure
      Bali.custom_icons = previous
    end
  end

  def test_cache_stops_growing_at_its_limit_and_still_renders
    with_empty_lucide_cache do
      stub_const(Bali::Icon::Component, :LUCIDE_SVGS_LIMIT, 1) do
        render_inline(Bali::Icon::Component.new("user"))
        render_inline(Bali::Icon::Component.new("arrow-left"))
      end

      assert_selector("svg.lucide-icon")
      assert_equal(1, lucide_svgs.size)
    end
  end

  private

  def lucide_svgs
    Bali::Icon::Component::LUCIDE_SVGS
  end

  def with_empty_lucide_cache
    lucide_svgs.clear
    yield
  ensure
    lucide_svgs.clear
  end
end
