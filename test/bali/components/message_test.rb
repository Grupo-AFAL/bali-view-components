# frozen_string_literal: true

require "test_helper"

class BaliMessageComponentTest < ComponentTestCase
  def test_renders_message_component_with_alert_role
    render_inline(Bali::Message::Component.new) { "Message content" }
    assert_selector('div.message-component.alert[role="alert"]', text: "Message content")
  end

  def test_applies_base_classes
    render_inline(Bali::Message::Component.new) { "Content" }
    assert_selector("div.alert.message-component")
  end
  Bali::Message::Component::COLORS.each do |color, css_class|
  define_method("test_colors_renders_#{color}_#{color}_with_#{css_class}") do
    render_inline(Bali::Message::Component.new(color: color)) { "Content" }
    assert_selector("div.alert.#{css_class}")
  end
  define_method("test_falls_back_to_primary_for_unknown_#{color}") do
    render_inline(Bali::Message::Component.new(color: :unknown)) { "Content" }
    assert_selector("div.alert.alert-info")
  end
  end

  def test_sizes_renders_small_size
    render_inline(Bali::Message::Component.new(size: :small)) { "Content" }
    assert_selector("div.alert.text-sm")
  end

  def test_sizes_renders_regular_size_no_extra_class
    render_inline(Bali::Message::Component.new(size: :regular)) { "Content" }
    assert_selector("div.alert")
    assert_no_selector("div.text-sm")
    assert_no_selector("div.text-lg")
  end

  def test_sizes_renders_medium_size
    render_inline(Bali::Message::Component.new(size: :medium)) { "Content" }
    assert_selector("div.alert.text-base")
  end

  def test_sizes_renders_large_size
    render_inline(Bali::Message::Component.new(size: :large)) { "Content" }
    assert_selector("div.alert.text-lg")
  end

  def test_sizes_falls_back_to_regular_for_unknown_size
    render_inline(Bali::Message::Component.new(size: :unknown)) { "Content" }
    assert_selector("div.alert")
  end

  def test_with_title_renders_title_in_bold_span
    render_inline(Bali::Message::Component.new(title: "My Title")) { "Content" }
    assert_selector("span.font-bold", text: "My Title")
    assert_selector("div.flex.flex-col.gap-1")
  end

  def test_with_title_renders_content_alongside_title
    render_inline(Bali::Message::Component.new(title: "Header")) { "Body text" }
    assert_selector("span.font-bold", text: "Header")
    assert_text("Body text")
  end

  def test_with_header_slot_renders_custom_header
    render_inline(Bali::Message::Component.new) do |c|
      c.with_header { "Custom Header" }
      "Body content"
    end
    assert_selector("div.flex.flex-col.gap-1")
    assert_text("Custom Header")
    assert_text("Body content")
  end

  def test_with_header_slot_prefers_title_over_header_slot
    render_inline(Bali::Message::Component.new(title: "Title wins")) do |c|
      c.with_header { "Header slot" }
      "Content"
    end
    assert_selector("span.font-bold", text: "Title wins")
    assert_no_text("Header slot")
  end

  def test_without_title_or_header_renders_content_directly
    render_inline(Bali::Message::Component.new) { "Simple message" }
    assert_selector("div.alert > span", text: "Simple message")
    assert_no_selector("div.flex.flex-col")
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Message::Component.new(class: "custom-class")) { "Content" }
    assert_selector("div.alert.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Message::Component.new(data: { testid: "my-message" })) { "Content" }
    assert_selector('div.alert[data-testid="my-message"]')
  end

  def test_options_passthrough_accepts_id_attribute
    render_inline(Bali::Message::Component.new(id: "unique-message")) { "Content" }
    assert_selector("div.alert#unique-message")
  end

  # Live-region role (issue #599)

  def test_role_defaults_to_alert
    render_inline(Bali::Message::Component.new) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  def test_role_status_renders_status_role
    render_inline(Bali::Message::Component.new(role: :status)) { "Content" }
    assert_selector('div.alert[role="status"]')
  end

  def test_role_note_renders_note_role
    render_inline(Bali::Message::Component.new(role: :note)) { "Content" }
    assert_selector('div.alert[role="note"]')
  end

  def test_role_falls_back_to_alert_for_unknown_role
    render_inline(Bali::Message::Component.new(role: :marquee)) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  def test_polite_maps_to_status_role
    render_inline(Bali::Message::Component.new(polite: true)) { "Content" }
    assert_selector('div.alert[role="status"]')
  end

  def test_assertive_maps_to_alert_role
    render_inline(Bali::Message::Component.new(assertive: true)) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  def test_explicit_role_wins_over_boolean_sugar
    render_inline(Bali::Message::Component.new(role: :note, assertive: true)) { "Content" }
    assert_selector('div.alert[role="note"]')
  end

  def test_assertive_wins_over_polite
    render_inline(Bali::Message::Component.new(polite: true, assertive: true)) { "Content" }
    assert_selector('div.alert[role="alert"]')
  end

  # Dismissible (issue #598)

  def test_not_dismissible_by_default
    render_inline(Bali::Message::Component.new) { "Content" }
    assert_no_selector('div.alert[data-controller~="message"]')
    assert_no_selector('button[data-action="message#dismiss"]')
  end

  def test_dismissible_wires_message_controller
    render_inline(Bali::Message::Component.new(dismissible: true)) { "Content" }
    assert_selector('div.message-component[data-controller~="message"]')
  end

  def test_dismissible_renders_close_button
    render_inline(Bali::Message::Component.new(dismissible: true)) { "Content" }
    assert_selector('button[data-action="message#dismiss"][aria-label="Close"]')
    assert_selector("button svg.lucide-icon")
  end

  def test_dismiss_id_adds_persistence_value
    render_inline(Bali::Message::Component.new(dismissible: true, dismiss_id: "welcome-banner")) { "Content" }
    assert_selector('div.message-component[data-message-dismiss-id-value="welcome-banner"]')
  end

  def test_dismiss_id_omitted_without_dismissible
    render_inline(Bali::Message::Component.new(dismiss_id: "welcome-banner")) { "Content" }
    assert_no_selector("div.alert[data-message-dismiss-id-value]")
  end
end
