# frozen_string_literal: true

require "test_helper"

class BaliGaugeComponentTest < ComponentTestCase
  def test_renders_the_ring_with_its_value_as_a_css_custom_property
    render_inline(Bali::Gauge::Component.new(value: 7, max: 10))

    assert_selector(".radial-progress")
    assert_includes page.native.to_html, "--value:70"
  end

  # daisyUI draws the arc from a CSS custom property, which assistive technology
  # cannot see. Without the full quartet the control is invisible, not merely
  # unlabelled — so this is the test that matters most in the file.
  def test_carries_the_whole_progressbar_aria_contract
    render_inline(Bali::Gauge::Component.new(value: 7, max: 10, label: "shifts"))

    assert_selector("[role='progressbar'][aria-valuenow='7'][aria-valuemin='0'][aria-valuemax='10']")
    assert_selector("[aria-label='shifts']")
  end

  # Only the DRAWING is clamped: 11 of 10 is a real state and `aria-valuenow`
  # must still report it, or the accessible reading and the truth diverge.
  def test_clamps_the_arc_but_reports_the_true_value
    render_inline(Bali::Gauge::Component.new(value: 11, max: 10))

    assert_includes page.native.to_html, "--value:100"
    assert_selector("[aria-valuenow='11']")
  end

  def test_a_zero_max_renders_empty_rather_than_raising
    render_inline(Bali::Gauge::Component.new(value: 5, max: 0))

    assert_includes page.native.to_html, "--value:0"
  end

  # The figure is already the ring's accessible name; without hiding the inner
  # text a screen reader reads it twice.
  def test_the_inner_text_is_hidden_from_assistive_technology
    render_inline(Bali::Gauge::Component.new(value: 7, max: 10, label: "shifts"))

    assert_selector("[aria-hidden='true']", text: "70%")
  end

  def test_falls_back_to_a_translated_label_when_none_is_given
    render_inline(Bali::Gauge::Component.new(value: 7, max: 10))

    assert_selector("[aria-label='70% complete']")
  end
end
