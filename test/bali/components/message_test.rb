# frozen_string_literal: true

require "test_helper"

class Bali_Message_ComponentTest < ComponentTestCase
  def test_renders_message_component_with_alert_role
    render_inline(Bali::Message::Component.new) { "Message content" }
    assert_selector('div.message-component.alert[role="alert"]', text: "Message content")
  end
  def test_applies_base_classes
    render_inline(Bali::Message::Component.new) { "Content" }
    assert_selector("div.alert.message-component")
  end
  #

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

  #

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
  #

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
  #

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
  #

  def test_without_title_or_header_renders_content_directly
    render_inline(Bali::Message::Component.new) { "Simple message" }
    assert_selector("div.alert > span", text: "Simple message")
    assert_no_selector("div.flex.flex-col")
  end
  #

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
end
