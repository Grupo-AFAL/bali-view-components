# frozen_string_literal: true

require "test_helper"

# Bali::FlashNotifications is the deprecated name of Bali::ToastContainer. What is
# tested here is the shim; the component's own behaviour lives in
# toast_container_test.rb.
class BaliFlashNotificationsComponentTest < ComponentTestCase
  def test_warns_through_the_bali_deprecator
    message = capture_deprecation { Bali::FlashNotifications::Component.new }

    assert_match("Bali::FlashNotifications::Component is deprecated", message)
    assert_match("Bali::ToastContainer::Component", message)
  end

  def test_renders_nothing_without_flash_messages
    silence_deprecations { render_inline(Bali::FlashNotifications::Component.new) }
    assert_no_selector("div.toast-component")
  end

  def test_notice_becomes_a_success_toast
    silence_deprecations { render_inline(Bali::FlashNotifications::Component.new(notice: "This is a notice")) }
    assert_selector("div.toast-component.alert-success", text: "This is a notice")
  end

  def test_alert_becomes_an_error_toast
    silence_deprecations { render_inline(Bali::FlashNotifications::Component.new(alert: "This is an alert")) }
    assert_selector("div.toast-component.alert-error", text: "This is an alert")
  end

  def test_renders_both
    silence_deprecations do
      render_inline(Bali::FlashNotifications::Component.new(notice: "Success message", alert: "Error message"))
    end

    assert_selector("div.toast-component", count: 2)
    assert_text("Success message")
    assert_text("Error message")
  end

  def test_notice_has_status_role
    silence_deprecations { render_inline(Bali::FlashNotifications::Component.new(notice: "Good news")) }
    assert_selector('div[role="status"]')
  end

  def test_alert_has_alert_role
    silence_deprecations { render_inline(Bali::FlashNotifications::Component.new(alert: "Bad news")) }
    assert_selector('div[role="alert"]')
  end

  # It is the fixed container now, which it was not before: it used to render two
  # inline notifications and leave the positioning to whoever wrapped it.
  def test_is_the_container
    silence_deprecations { render_inline(Bali::FlashNotifications::Component.new(notice: "Saved")) }
    assert_selector("div.toast.toast-container-component > div.toast-component")
  end
end
