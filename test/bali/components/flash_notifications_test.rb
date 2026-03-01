# frozen_string_literal: true

require "test_helper"

class BaliFlashNotificationsComponentTest < ComponentTestCase
  def test_rendering_without_notice_and_alert_does_not_render_any_notification
    render_inline(Bali::FlashNotifications::Component.new)
    assert_no_selector("div.notification-component")
  end

  def test_rendering_with_notice_renders_a_success_notification
    render_inline(Bali::FlashNotifications::Component.new(notice: "This is a notice"))
    assert_selector("div.notification-component.alert-success", text: "This is a notice")
  end

  def test_rendering_with_alert_renders_an_error_notification
    render_inline(Bali::FlashNotifications::Component.new(alert: "This is an alert"))
    assert_selector("div.notification-component.alert-error", text: "This is an alert")
  end

  def test_rendering_with_both_notice_and_alert_renders_both_notifications
    render_inline(Bali::FlashNotifications::Component.new(notice: "Success message", alert: "Error message"))
    assert_selector("div.alert-success", text: "Success message")
    assert_selector("div.alert-error", text: "Error message")
  end

  def test_flash_type_mapping_maps_notice_to_success_type
    render_inline(Bali::FlashNotifications::Component.new(notice: "Good news"))
    assert_selector(".alert-success")
    assert_no_selector(".alert-error")
  end

  def test_flash_type_mapping_maps_alert_to_error_type
    render_inline(Bali::FlashNotifications::Component.new(alert: "Bad news"))
    assert_selector(".alert-error")
    assert_no_selector(".alert-success")
  end
end
