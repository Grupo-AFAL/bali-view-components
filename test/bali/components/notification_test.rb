# frozen_string_literal: true

require "test_helper"

class BaliNotificationComponentTest < ComponentTestCase
  def test_basic_rendering_renders_alert_with_default_success_type
    render_inline(Bali::Notification::Component.new) do
      "Hello World!"
    end
    assert_selector("div.notification-component.alert", text: "Hello World!")
    assert_selector("div.alert-success")
  end

  def test_basic_rendering_renders_with_stimulus_controller
    render_inline(Bali::Notification::Component.new)
    assert_selector('[data-controller="notification"]')
    assert_selector('[data-notification-delay-value="3000"]')
    assert_selector('[data-notification-dismiss-value="true"]')
  end

  def test_basic_rendering_renders_close_button_with_i18n_aria_label
    render_inline(Bali::Notification::Component.new)
    assert_selector('button[data-action="notification#close"]')
    assert_selector('button[aria-label="Close notification"]')
  end

  def test_basic_rendering_renders_base_classes
    render_inline(Bali::Notification::Component.new(fixed: false))
    assert_selector("div.notification-component.alert")
  end
  Bali::Notification::Component::TYPES.each_key do |type|
    next if %i[danger primary].include?(type) # aliases

    define_method("test_types_renders_#{type}_type") do
      render_inline(Bali::Notification::Component.new(type: type, fixed: false))
      assert_selector("div.alert.#{Bali::Notification::Component::TYPES[type]}")
    end
  end

  def test_maps_danger_to_error
    render_inline(Bali::Notification::Component.new(type: :danger, fixed: false))
    assert_selector("div.alert.alert-error")
  end

  def test_maps_primary_to_info
    render_inline(Bali::Notification::Component.new(type: :primary, fixed: false))
    assert_selector("div.alert.alert-info")
  end

  def test_falls_back_to_success_for_unknown_types
    render_inline(Bali::Notification::Component.new(type: :unknown, fixed: false))
    assert_selector("div.alert.alert-success")
  end

  def test_fixed_positioning_renders_fixed_classes_when_fixed_is_true
    render_inline(Bali::Notification::Component.new(fixed: true))
    assert_selector("div.alert.fixed")
  end

  def test_fixed_positioning_does_not_render_fixed_classes_when_fixed_is_false
    render_inline(Bali::Notification::Component.new(fixed: false))
    assert_no_selector("div.fixed")
  end

  def test_dismiss_configuration_sets_dismiss_value_to_true
    render_inline(Bali::Notification::Component.new(dismiss: true))
    assert_selector('[data-notification-dismiss-value="true"]')
  end

  def test_dismiss_configuration_sets_dismiss_value_to_false
    render_inline(Bali::Notification::Component.new(dismiss: false))
    assert_selector('[data-notification-dismiss-value="false"]')
  end

  def test_custom_delay_sets_custom_delay_value
    render_inline(Bali::Notification::Component.new(delay: 5000))
    assert_selector('[data-notification-delay-value="5000"]')
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Notification::Component.new(fixed: false, class: "my-custom-class"))
    assert_selector("div.notification-component.my-custom-class")
  end

  def test_constants_has_frozen_types_constant
    assert(Bali::Notification::Component::TYPES.frozen?)
  end

  def test_constants_has_base_classes_constant
    assert_equal("notification-component alert", Bali::Notification::Component::BASE_CLASSES)
  end
end
