# frozen_string_literal: true

require "test_helper"

class BaliToastContainerComponentTest < ComponentTestCase
  def test_renders_the_daisyui_toast_stack
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "Saved" }))
    assert_selector("div.toast.toast-container-component")
  end

  def test_renders_nothing_for_an_empty_flash
    render_inline(Bali::ToastContainer::Component.new(flash: {}))
    assert_no_selector("div.toast-component")
  end

  def test_renders_nothing_without_a_flash
    render_inline(Bali::ToastContainer::Component.new)
    assert_no_selector("div.toast-component")
  end

  def test_notice_becomes_a_success_toast
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "This is a notice" }))
    assert_selector("div.toast-component.alert-success", text: "This is a notice")
  end

  def test_alert_becomes_an_error_toast
    render_inline(Bali::ToastContainer::Component.new(flash: { alert: "This is an alert" }))
    assert_selector("div.toast-component.alert-error", text: "This is an alert")
  end

  def test_renders_both_rails_flash_keys
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "Success message", alert: "Error message" }))
    assert_selector("div.toast-component", count: 2)
    assert_text("Success message")
    assert_text("Error message")
  end

  # The reason for the rename: FlashNotifications only knew `notice:` and
  # `alert:`, so these three were dropped by every caller that passed the flash
  # through.
  def test_maps_the_keys_flash_notifications_used_to_drop
    render_inline(Bali::ToastContainer::Component.new(
      flash: { warning: "Careful", info: "Heads up", success: "Done", error: "Broken" }
    ))
    assert_selector("div.toast-component.alert-warning", text: "Careful")
    assert_selector("div.toast-component.alert-info", text: "Heads up")
    assert_selector("div.toast-component.alert-success", text: "Done")
    assert_selector("div.toast-component.alert-error", text: "Broken")
  end

  def test_accepts_string_keys
    render_inline(Bali::ToastContainer::Component.new(flash: { "notice" => "From a string key" }))
    assert_selector("div.toast-component.alert-success", text: "From a string key")
  end

  # `flash[:timedout]` and friends are state, not messages.
  def test_ignores_keys_it_does_not_know
    render_inline(Bali::ToastContainer::Component.new(flash: { timedout: true, notice: "Saved" }))
    assert_selector("div.toast-component", count: 1)
    assert_text("Saved")
  end

  def test_ignores_blank_messages
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "", alert: nil }))
    assert_no_selector("div.toast-component")
  end

  def test_defaults_to_the_bottom_end_corner
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "Saved" }))
    assert_selector("div.toast.toast-bottom.toast-end")
  end

  Bali::ToastContainer::Component::POSITIONS.each do |position, classes|
    define_method("test_position_#{position}") do
      render_inline(Bali::ToastContainer::Component.new(position: position, flash: { notice: "Saved" }))
      assert_selector("div.toast.#{classes.tr(' ', '.')}")
    end
  end

  def test_unknown_position_falls_back_to_bottom_end
    render_inline(Bali::ToastContainer::Component.new(position: :nowhere, flash: { notice: "Saved" }))
    assert_selector("div.toast.toast-bottom.toast-end")
  end

  # daisyUI's `.toast` has no z-index of its own, so a toast reporting on a modal
  # would otherwise render underneath it.
  def test_sits_on_the_toast_layer_of_the_z_index_scale
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "Saved" }))
    assert_selector('div[class*="z-[var(--bali-z-toast)]"]')
  end

  def test_duration_is_passed_down_to_every_flash_toast
    render_inline(Bali::ToastContainer::Component.new(duration: 9000, flash: { notice: "Saved" }))
    assert_selector('div.toast-component[data-alert-duration-value="9000"]')
  end

  def test_toasts_can_be_given_one_by_one
    render_inline(Bali::ToastContainer::Component.new) do |container|
      container.with_toast(color: :info, duration: nil) { "One toast." }
      container.with_toast(color: :success, duration: nil) { "Another toast." }
    end

    assert_selector("div.toast-component", count: 2)
    assert_selector("div.toast-component.alert-info", text: "One toast.")
    assert_selector("div.toast-component.alert-success", text: "Another toast.")
  end

  def test_options_passthrough
    render_inline(Bali::ToastContainer::Component.new(id: "toast-notifications", flash: { notice: "Saved" }))
    assert_selector("div.toast#toast-notifications")
  end

  # The container is furniture. Making it a live region as well as its children
  # nested one aria-live inside another, which is what Bali::AppLayout used to do.
  def test_the_container_is_not_a_live_region
    render_inline(Bali::ToastContainer::Component.new(flash: { notice: "Saved" }))
    assert_no_selector("div.toast[aria-live]")
    assert_no_selector("div.toast[role]")
  end

  def test_constants_are_frozen
    assert(Bali::ToastContainer::Component::POSITIONS.frozen?)
    assert(Bali::ToastContainer::Component::FLASH_COLORS.frozen?)
  end
end
