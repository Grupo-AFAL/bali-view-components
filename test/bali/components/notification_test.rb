# frozen_string_literal: true

require "test_helper"

# Bali::Notification is the deprecated name of Bali::Toast plus, when `fixed:` is
# on, a Bali::ToastContainer around it. What is tested here is the shim: that it
# still renders, that it translates the keywords whose meaning changed, and that
# it says so. The components' own behaviour lives in toast_test.rb and
# toast_container_test.rb.
class BaliNotificationComponentTest < ComponentTestCase
  def test_warns_through_the_bali_deprecator
    message = capture_deprecation { Bali::Notification::Component.new }

    assert_match("Bali::Notification::Component is deprecated", message)
    assert_match("Bali::Toast::Component", message)
  end

  def test_still_renders_the_alert
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: false)) { "Hello World!" } }
    assert_selector("div.toast-component.alert", text: "Hello World!")
  end

  def test_default_type_is_still_success
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: false)) }
    assert_selector("div.alert.alert-success")
  end

  def test_type_becomes_color
    silence_deprecations { render_inline(Bali::Notification::Component.new(type: :warning, fixed: false)) }
    assert_selector("div.alert.alert-warning")
  end

  Bali::Notification::Component::LEGACY_COLORS.each do |legacy, replacement|
    define_method("test_legacy_type_#{legacy}_renders_as_#{replacement}") do
      silence_deprecations { render_inline(Bali::Notification::Component.new(type: legacy, fixed: false)) }
      assert_selector("div.alert.#{Bali::Alert::Component::COLORS[replacement]}")
    end
  end

  # `delay:` and `dismiss:` were two keywords for one thing: how long the toast
  # stays. They collapse into `duration:`.
  def test_delay_becomes_duration
    silence_deprecations { render_inline(Bali::Notification::Component.new(delay: 5000, fixed: false)) }
    assert_selector('div[data-alert-duration-value="5000"]')
  end

  def test_dismiss_false_means_no_duration
    silence_deprecations { render_inline(Bali::Notification::Component.new(dismiss: false, fixed: false)) }
    assert_no_selector("div[data-alert-duration-value]")
  end

  def test_dismiss_true_keeps_the_default_delay
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: false)) }
    assert_selector('div[data-alert-duration-value="3000"]')
  end

  # `fixed:` used to position the alert itself; the replacement is a container
  # around it, which is what the shim emits.
  def test_fixed_wraps_the_alert_in_a_toast_container
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: true)) }
    assert_selector("div.toast.toast-container-component > div.toast-component")
  end

  def test_not_fixed_renders_the_alert_on_its_own
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: false)) }
    assert_no_selector("div.toast-container-component")
  end

  def test_legacy_positions_map_to_the_container_positions
    silence_deprecations { render_inline(Bali::Notification::Component.new(position: :top_right)) }
    assert_selector("div.toast.toast-top.toast-end")

    silence_deprecations { render_inline(Bali::Notification::Component.new(position: :bottom_right)) }
    assert_selector("div.toast.toast-bottom.toast-end")
  end

  def test_renders_the_close_button
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: false)) }
    assert_selector('button[data-action="alert#dismiss"] .lucide-icon')
  end

  def test_renders_the_type_icon
    silence_deprecations { render_inline(Bali::Notification::Component.new(type: :success, fixed: false)) }
    assert_selector("div.alert > span.icon-component")
  end

  def test_success_has_status_role
    silence_deprecations { render_inline(Bali::Notification::Component.new(type: :success, fixed: false)) }
    assert_selector('div[role="status"]')
  end

  def test_error_has_alert_role
    silence_deprecations { render_inline(Bali::Notification::Component.new(type: :error, fixed: false)) }
    assert_selector('div[role="alert"]')
  end

  def test_danger_has_alert_role
    silence_deprecations { render_inline(Bali::Notification::Component.new(type: :danger, fixed: false)) }
    assert_selector('div[role="alert"]')
  end

  def test_options_passthrough_accepts_custom_classes
    silence_deprecations { render_inline(Bali::Notification::Component.new(fixed: false, class: "my-custom-class")) }
    assert_selector("div.toast-component.my-custom-class")
  end
end
