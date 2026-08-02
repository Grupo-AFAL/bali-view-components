# frozen_string_literal: true

require "test_helper"

class BaliToastComponentTest < ComponentTestCase
  def test_renders_an_alert
    render_inline(Bali::Toast::Component.new) { "Hello World!" }
    assert_selector("div.toast-component.alert.alert-component", text: "Hello World!")
  end

  def test_defaults_to_info
    render_inline(Bali::Toast::Component.new) { "Content" }
    assert_selector("div.alert.alert-info")
  end

  def test_carries_the_shadow
    render_inline(Bali::Toast::Component.new) { "Content" }
    assert_selector("div.toast-component.shadow-xl")
  end

  Bali::Alert::Component::COLORS.each_key do |color|
    define_method("test_colors_renders_#{color}") do
      render_inline(Bali::Toast::Component.new(color: color)) { "Content" }
      css_class = Bali::Alert::Component::COLORS[color]
      assert_selector(css_class.present? ? "div.alert.#{css_class}" : "div.alert")
    end
  end

  # A toast does not position itself: Bali::ToastContainer does. v2's Notification
  # carried `fixed:` and `position:`, which is why every stack of them had to be
  # assembled by hand around it.
  def test_does_not_position_itself
    render_inline(Bali::Toast::Component.new) { "Content" }
    assert_no_selector("div.fixed")
    assert_no_selector("div.toast")
  end

  def test_auto_closes_after_the_default_duration
    render_inline(Bali::Toast::Component.new) { "Content" }
    assert_selector('div[data-controller~="alert"][data-alert-duration-value="3000"]')
  end

  def test_custom_duration
    render_inline(Bali::Toast::Component.new(duration: 8000)) { "Content" }
    assert_selector('div[data-alert-duration-value="8000"]')
  end

  def test_nil_duration_never_auto_closes
    render_inline(Bali::Toast::Component.new(duration: nil)) { "Content" }
    assert_no_selector("div[data-alert-duration-value]")
  end

  # The controller reads the leaving animation's length back from the CSS, so the
  # class is all it needs to be told.
  def test_declares_the_leaving_class
    render_inline(Bali::Toast::Component.new) { "Content" }
    assert_selector('div[data-alert-leaving-class="toast-leaving"]')
  end

  def test_leaving_class_can_be_overridden
    render_inline(Bali::Toast::Component.new(data: { alert_leaving_class: "my-fade" })) { "Content" }
    assert_selector('div[data-alert-leaving-class="my-fade"]')
  end

  # `closable:` is a real keyword now. v2 always rendered the button and hid it
  # with an `is-unclosable` class the gem never set on anything.
  def test_closable_by_default
    render_inline(Bali::Toast::Component.new) { "Content" }
    assert_selector('button[data-action="alert#dismiss"][aria-label="Close alert"]')
  end

  def test_not_closable_renders_no_button
    render_inline(Bali::Toast::Component.new(closable: false)) { "Content" }
    assert_no_selector('button[data-action="alert#dismiss"]')
  end

  def test_renders_the_icon_for_its_color
    render_inline(Bali::Toast::Component.new(color: :success)) { "Content" }
    assert_selector("div.alert > span.icon-component")
  end

  def test_icon_can_be_dropped
    render_inline(Bali::Toast::Component.new(icon: nil)) { "Content" }
    assert_no_selector("div.alert > span.icon-component")
  end

  def test_success_has_status_role
    render_inline(Bali::Toast::Component.new(color: :success)) { "Content" }
    assert_selector('div[role="status"]')
  end

  def test_error_has_alert_role
    render_inline(Bali::Toast::Component.new(color: :error)) { "Content" }
    assert_selector('div[role="alert"]')
  end

  def test_warning_has_status_role
    render_inline(Bali::Toast::Component.new(color: :warning)) { "Content" }
    assert_selector('div[role="status"]')
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Toast::Component.new(class: "my-custom-class")) { "Content" }
    assert_selector("div.toast-component.my-custom-class")
  end

  def test_title_is_forwarded_to_the_alert
    render_inline(Bali::Toast::Component.new(title: "Saved")) { "Content" }
    assert_selector("span.font-bold", text: "Saved")
  end
end
