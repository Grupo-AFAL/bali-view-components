# frozen_string_literal: true

require "test_helper"

# Bali::Message is the deprecated name of Bali::Alert. What is tested here is the
# shim: that it still renders, that it translates the two keywords whose names
# changed, and that it says so. The component's own behaviour lives in
# alert_test.rb.
class BaliMessageComponentTest < ComponentTestCase
  def test_warns_through_the_bali_deprecator
    message = capture_deprecation { Bali::Message::Component.new }

    assert_match("Bali::Message::Component is deprecated", message)
    assert_match("Bali::Alert::Component", message)
  end

  def test_still_renders_the_alert
    silence_deprecations { render_inline(Bali::Message::Component.new) { "Message content" } }
    assert_selector("div.alert.alert-component", text: "Message content")
  end

  def test_default_color_still_renders_alert_info
    silence_deprecations { render_inline(Bali::Message::Component.new) { "Content" } }
    assert_selector("div.alert.alert-info")
  end

  Bali::Message::Component::LEGACY_COLORS.each do |legacy, replacement|
    define_method("test_legacy_color_#{legacy}_renders_as_#{replacement}") do
      silence_deprecations { render_inline(Bali::Message::Component.new(color: legacy)) { "Content" } }
      css_class = Bali::Alert::Component::COLORS[replacement]
      assert_selector(css_class.present? ? "div.alert.#{css_class}" : "div.alert")
    end
  end

  def test_new_color_names_pass_straight_through
    silence_deprecations { render_inline(Bali::Message::Component.new(color: :warning)) { "Content" } }
    assert_selector("div.alert.alert-warning")
  end

  def test_dismissible_becomes_closable
    silence_deprecations { render_inline(Bali::Message::Component.new(dismissible: true)) { "Content" } }
    assert_selector('button[data-action="alert#dismiss"]')
    assert_selector('div[data-controller~="alert"]')
  end

  def test_the_header_slot_still_works
    silence_deprecations do
      render_inline(Bali::Message::Component.new) do |c|
        c.with_header { "Custom Header" }
        "Body content"
      end
    end

    assert_text("Custom Header")
    assert_text("Body content")
  end

  # The one behaviour that does change under the shim, and the reason it is worth
  # changing: v2 gave every message role="alert", so an informational banner
  # interrupted the screen reader.
  def test_a_non_error_message_no_longer_interrupts_the_screen_reader
    silence_deprecations { render_inline(Bali::Message::Component.new(color: :info)) { "Content" } }
    assert_selector('div.alert[role="status"]')
  end
end
