# frozen_string_literal: true

require "test_helper"

class BaliBooleanIconComponentTest < ComponentTestCase
  #

  def test_with_true_value_renders_success_styling
    render_inline(Bali::BooleanIcon::Component.new(value: true))
    assert_selector("div.boolean-icon-component.text-success")
  end

  def test_with_true_value_renders_check_circle_icon
    render_inline(Bali::BooleanIcon::Component.new(value: true))
    # Verify icon is rendered (SVG with path)
    assert_selector(".icon-component svg")
  end
  #

  def test_with_false_value_renders_error_styling
    render_inline(Bali::BooleanIcon::Component.new(value: false))
    assert_selector("div.boolean-icon-component.text-error")
  end

  def test_with_false_value_renders_times_circle_icon
    render_inline(Bali::BooleanIcon::Component.new(value: false))
    # Verify icon is rendered (SVG with path)
    assert_selector(".icon-component svg")
  end
  #

  def test_with_nil_value_treats_nil_as_false
    render_inline(Bali::BooleanIcon::Component.new(value: nil))
    assert_selector("div.boolean-icon-component.text-error")
    assert_selector(".icon-component svg")
  end
  #

  def test_options_passthrough_merges_custom_classes
    render_inline(Bali::BooleanIcon::Component.new(value: true, class: "custom-class"))
    assert_selector("div.boolean-icon-component.custom-class")
  end

  def test_options_passthrough_passes_data_attributes
    render_inline(Bali::BooleanIcon::Component.new(value: true, data: { testid: "boolean-icon" }))
    assert_selector('[data-testid="boolean-icon"]')
  end
end
