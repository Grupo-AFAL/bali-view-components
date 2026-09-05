# frozen_string_literal: true

require "test_helper"

class BaliAlertComponentTest < ComponentTestCase
  def test_renders_alert_component
    render_inline(Bali::Alert::Component.new) { "Alert content" }
    assert_selector("div.alert-component.alert", text: "Alert content")
  end

  def test_applies_base_classes
    render_inline(Bali::Alert::Component.new) { "Content" }
    assert_selector("div.alert.alert-component")
  end

  Bali::Alert::Component::COLORS.each do |color, css_class|
    define_method("test_colors_renders_#{color}") do
      render_inline(Bali::Alert::Component.new(color: color)) { "Content" }
      assert_selector(css_class.present? ? "div.alert.#{css_class}" : "div.alert")
    end
  end

  def test_neutral_renders_no_color_class
    render_inline(Bali::Alert::Component.new(color: :neutral)) { "Content" }
    assert_selector("div.alert")
    assert_no_selector("div.alert-info")
    assert_no_selector("div.alert-error")
  end

  # An unknown colour used to fall back to `alert-info`, which is how `:primary`,
  # `:secondary` and `:link` survived two majors past Bulma.
  def test_unknown_color_raises
    error = assert_raises(ArgumentError) { Bali::Alert::Component.new(color: :chartreuse) }
    assert_match("unknown color :chartreuse", error.message)
  end

  def test_removed_bulma_name_names_its_replacement
    error = assert_raises(ArgumentError) { Bali::Alert::Component.new(color: :danger) }
    assert_match("color: :error", error.message)
  end

  # There is no `alert-primary` in daisyUI, so `:primary` is not a colour an alert
  # can be, even though it is a valid Bali::Color name elsewhere.
  def test_primary_is_not_an_alert_color
    error = assert_raises(ArgumentError) { Bali::Alert::Component.new(color: :primary) }
    assert_match("unknown color :primary", error.message)
  end

  def test_sizes_render_the_shared_scale
    { xs: "text-xs", sm: "text-sm", lg: "text-lg", xl: "text-xl" }.each do |size, klass|
      render_inline(Bali::Alert::Component.new(size: size)) { "Content" }
      assert_selector("div.alert.#{klass}")
    end
  end

  def test_md_is_the_default_and_carries_no_size_class
    render_inline(Bali::Alert::Component.new(size: :md)) { "Content" }
    assert_selector("div.alert")
    assert_no_selector("div.text-sm")
    assert_no_selector("div.text-lg")
  end

  # Legacy small/regular/medium/large still resolve, mapped to the shared scale.
  def test_legacy_size_names_still_resolve
    render_inline(Bali::Alert::Component.new(size: :small)) { "Content" }
    assert_selector("div.alert.text-sm")

    render_inline(Bali::Alert::Component.new(size: :large)) { "Content" }
    assert_selector("div.alert.text-lg")

    # `regular` and `medium` both map to md — base font, no size class.
    render_inline(Bali::Alert::Component.new(size: :regular)) { "Content" }
    assert_no_selector("div.text-sm")

    render_inline(Bali::Alert::Component.new(size: :medium)) { "Content" }
    assert_no_selector("div.text-lg")
  end

  def test_an_unknown_size_raises_instead_of_defaulting_in_silence
    error = assert_raises(ArgumentError) do
      render_inline(Bali::Alert::Component.new(size: :unknown)) { "Content" }
    end
    assert_match(/unknown size :unknown/, error.message)
  end

  def test_styles_render_their_daisyui_class
    Bali::Alert::Component::STYLES.each do |style, css_class|
      render_inline(Bali::Alert::Component.new(style: style)) { "Content" }
      assert_selector("div.alert.#{css_class}")
    end
  end

  def test_with_title_renders_title_in_bold_span
    render_inline(Bali::Alert::Component.new(title: "My Title")) { "Content" }
    assert_selector("span.font-bold", text: "My Title")
    assert_selector("div.flex.flex-col.gap-1")
  end

  def test_with_title_renders_content_alongside_title
    render_inline(Bali::Alert::Component.new(title: "Header")) { "Body text" }
    assert_selector("span.font-bold", text: "Header")
    assert_text("Body text")
  end

  def test_with_header_slot_renders_custom_header
    render_inline(Bali::Alert::Component.new) do |c|
      c.with_header { "Custom Header" }
      "Body content"
    end
    assert_selector("div.flex.flex-col.gap-1")
    assert_text("Custom Header")
    assert_text("Body content")
  end

  def test_with_header_slot_prefers_title_over_header_slot
    render_inline(Bali::Alert::Component.new(title: "Title wins")) do |c|
      c.with_header { "Header slot" }
      "Content"
    end
    assert_selector("span.font-bold", text: "Title wins")
    assert_no_text("Header slot")
  end

  def test_without_title_or_header_renders_content_directly
    render_inline(Bali::Alert::Component.new) { "Simple alert" }
    assert_selector("div.alert > div", text: "Simple alert")
    assert_no_selector("div.flex.flex-col")
  end

  # The body used to be a `<span>`, and a list or a paragraph inside it is block-in-inline:
  # invalid HTML that browsers paint anyway, so nothing said so until a validator did
  # (#1120). The alert is a grid and its column a flex column, so the wrapper's own
  # display never mattered to the layout — a `<div>` draws the same and takes any content.
  def test_block_content_is_not_wrapped_in_an_inline_element
    render_inline(Bali::Alert::Component.new(title: "Sin gerente")) do
      "<ul><li>124 · CABO</li></ul>".html_safe
    end

    assert_selector("div.alert div.flex.flex-col > div > ul > li", text: "124 · CABO")
    assert_no_selector("span ul")
  end

  def test_block_content_without_a_title_is_not_wrapped_in_an_inline_element_either
    render_inline(Bali::Alert::Component.new) { "<p>Un párrafo</p>".html_safe }

    assert_selector("div.alert > div > p", text: "Un párrafo")
    assert_no_selector("span p")
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Alert::Component.new(class: "custom-class")) { "Content" }
    assert_selector("div.alert.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Alert::Component.new(data: { testid: "my-alert" })) { "Content" }
    assert_selector('div.alert[data-testid="my-alert"]')
  end

  def test_options_passthrough_accepts_id_attribute
    render_inline(Bali::Alert::Component.new(id: "unique-alert")) { "Content" }
    assert_selector("div.alert#unique-alert")
  end

  # Icons

  def test_no_icon_by_default
    render_inline(Bali::Alert::Component.new) { "Content" }
    assert_no_selector("div.alert > span.icon-component")
  end

  # The rendered SVG carries no per-icon class, so "the right icon" is asserted by
  # comparing `icon: true` against the name it is supposed to resolve to.
  def test_icon_true_uses_the_icon_for_the_color
    render_inline(Bali::Alert::Component.new(color: :success, icon: true)) { "Content" }
    assert_selector("div.alert > span.icon-component")
    resolved = rendered_content

    render_inline(Bali::Alert::Component.new(color: :success, icon: "circle-check")) { "Content" }
    assert_equal(rendered_content, resolved)
  end

  def test_icon_string_names_the_icon
    render_inline(Bali::Alert::Component.new(icon: "star")) { "Content" }
    assert_selector("div.alert > span.icon-component")
    star = rendered_content

    render_inline(Bali::Alert::Component.new(icon: "info")) { "Content" }
    refute_equal(rendered_content, star)
  end

  def test_every_color_has_an_icon
    assert_equal(Bali::Alert::Component::COLORS.keys.sort, Bali::Alert::Component::ICONS.keys.sort)
  end

  # Live-region role. v2's Message defaulted every alert to role="alert", so an
  # informational banner interrupted the screen reader mid-sentence.

  def test_role_defaults_to_status
    render_inline(Bali::Alert::Component.new) { "Content" }
    assert_selector('div.alert[role="status"]')
  end

  def test_error_defaults_to_the_assertive_role
    render_inline(Bali::Alert::Component.new(color: :error)) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  def test_success_defaults_to_the_polite_role
    render_inline(Bali::Alert::Component.new(color: :success)) { "Content" }
    assert_selector('div.alert[role="status"]')
  end

  def test_warning_defaults_to_the_polite_role
    render_inline(Bali::Alert::Component.new(color: :warning)) { "Content" }
    assert_selector('div.alert[role="status"]')
  end

  def test_role_note_renders_note_role
    render_inline(Bali::Alert::Component.new(role: :note)) { "Content" }
    assert_selector('div.alert[role="note"]')
  end

  def test_unknown_role_raises
    error = assert_raises(ArgumentError) { Bali::Alert::Component.new(role: :marquee) }
    assert_match("unknown role :marquee", error.message)
  end

  def test_polite_maps_to_status_role
    render_inline(Bali::Alert::Component.new(color: :error, polite: true)) { "Content" }
    assert_selector('div.alert[role="status"]')
  end

  def test_assertive_maps_to_alert_role
    render_inline(Bali::Alert::Component.new(assertive: true)) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  def test_explicit_role_wins_over_boolean_sugar
    render_inline(Bali::Alert::Component.new(role: :note, assertive: true)) { "Content" }
    assert_selector('div.alert[role="note"]')
  end

  def test_assertive_wins_over_polite
    render_inline(Bali::Alert::Component.new(polite: true, assertive: true)) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  # Closing

  def test_not_closable_by_default
    render_inline(Bali::Alert::Component.new) { "Content" }
    assert_no_selector('div.alert[data-controller~="alert"]')
    assert_no_selector('button[data-action="alert#dismiss"]')
  end

  def test_closable_wires_the_alert_controller
    render_inline(Bali::Alert::Component.new(closable: true)) { "Content" }
    assert_selector('div.alert-component[data-controller~="alert"]')
  end

  # "Close alert", not "Close": a page can hold several closable things, and a
  # bare "Close" gives a screen reader no way to tell them apart.
  def test_closable_renders_close_button
    render_inline(Bali::Alert::Component.new(closable: true)) { "Content" }
    assert_selector('button[data-action="alert#dismiss"][aria-label="Close alert"]')
    assert_selector("button svg.lucide-icon")
  end

  def test_dismiss_id_adds_persistence_value
    render_inline(Bali::Alert::Component.new(closable: true, dismiss_id: "welcome-banner")) { "Content" }
    assert_selector('div.alert-component[data-alert-dismiss-id-value="welcome-banner"]')
  end

  # `dismiss_id:` on its own is enough to wire the controller: an alert can be
  # remembered as dismissed without offering a button of its own.
  def test_dismiss_id_alone_wires_the_controller
    render_inline(Bali::Alert::Component.new(dismiss_id: "welcome-banner")) { "Content" }
    assert_selector('div.alert-component[data-controller~="alert"]')
    assert_no_selector('button[data-action="alert#dismiss"]')
  end

  def test_duration_wires_the_controller
    render_inline(Bali::Alert::Component.new(duration: 4000)) { "Content" }
    assert_selector('div.alert-component[data-controller~="alert"][data-alert-duration-value="4000"]')
  end

  def test_no_duration_value_without_a_duration
    render_inline(Bali::Alert::Component.new(closable: true)) { "Content" }
    assert_no_selector("div.alert[data-alert-duration-value]")
  end

  def test_constants_are_frozen
    assert(Bali::Alert::Component::COLORS.frozen?)
    assert(Bali::Alert::Component::ICONS.frozen?)
    assert(Bali::Alert::Component::STYLES.frozen?)
    assert(Bali::Alert::Component::SIZES.frozen?)
  end
end
