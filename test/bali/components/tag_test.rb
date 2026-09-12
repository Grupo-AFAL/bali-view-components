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

  def test_icon_keyword_renders_the_icon_before_the_text
    render_inline(Bali::Tag::Component.new(text: "Done", icon: "check"))
    assert_selector("div.badge span.icon-component svg")
    html = page.native.to_html
    assert_operator html.index("icon-component"), :<, html.index("Done")
  end

  # The keyword glyph is drawn at the pill's font-size: a default 16px icon is
  # as tall as the whole `badge-xs` pill, so it would touch both edges.
  def test_icon_keyword_sizes_the_glyph_to_the_pill
    render_inline(Bali::Tag::Component.new(text: "Done", icon: "check", size: :xs))
    assert_selector('.icon-component[style*="--bali-icon-size: 10px"]')
  end

  def test_icon_keyword_without_a_size_uses_the_md_glyph
    render_inline(Bali::Tag::Component.new(text: "Done", icon: "check"))
    assert_selector('.icon-component[style*="--bali-icon-size: 14px"]')
  end

  def test_icon_slot_wins_over_the_keyword
    render_inline(Bali::Tag::Component.new(text: "Done", icon: "check")) do |tag|
      tag.with_icon("star", class: "slot-icon")
    end
    assert_selector("span.icon-component.slot-icon", count: 1)
    assert_selector("span.icon-component", count: 1)
  end

  def test_for_resolves_color_icon_and_i18n_label_from_the_map
    I18n.backend.store_translations(:en, tickets: { statuses: { active: "Active!" } })
    render_inline(Bali::Tag.for(:active,
                                map: { active: { color: :success, icon: "check" } },
                                i18n_scope: "tickets.statuses"))
    assert_selector("div.badge.badge-success span.icon-component svg")
    assert_selector("div.badge", text: "Active!")
  ensure
    I18n.backend.reload!
  end

  def test_for_humanizes_the_value_without_an_i18n_scope
    render_inline(Bali::Tag.for(:in_review, map: { in_review: :info }))
    assert_selector("div.badge.badge-info", text: "In review")
  end

  def test_for_matches_string_map_keys_and_string_values
    render_inline(Bali::Tag.for(:urgent, map: { "urgent" => :error }))
    assert_selector("div.badge.badge-error", text: "Urgent")

    render_inline(Bali::Tag.for("urgent", map: { urgent: :error }))
    assert_selector("div.badge.badge-error", text: "Urgent")
  end

  def test_for_raises_on_an_unmapped_value_without_a_default
    error = assert_raises(ArgumentError) do
      Bali::Tag.for(:unknown, map: { active: :success })
    end
    assert_includes error.message, ":unknown"
    assert_includes error.message, "default"
  end

  def test_for_uses_the_default_entry_for_an_unmapped_value
    render_inline(Bali::Tag.for(:legacy, map: { active: :success }, default: :ghost))
    assert_selector("div.badge.badge-ghost", text: "Legacy")
  end

  def test_for_entry_text_overrides_the_label
    render_inline(Bali::Tag.for(nil, map: {}, default: { color: :ghost, text: "—" }))
    assert_selector("div.badge.badge-ghost", text: "—")
  end

  def test_for_passes_tag_options_through_and_the_entry_wins_on_conflict
    render_inline(Bali::Tag.for(:active,
                                map: { active: { color: :success } },
                                size: :xs, rounded: true, color: :error))
    assert_selector("div.badge.badge-success.badge-xs.rounded-full")
    assert_no_selector(".badge-error")
  end
end
