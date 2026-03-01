# frozen_string_literal: true

require "test_helper"

class BaliLabelValueComponentTest < ComponentTestCase
  def test_renders_with_label_and_value
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Juan Perez"))
    assert_selector("label", text: "Name")
    assert_selector("div.min-h-6", text: "Juan Perez")
  end

  def test_renders_with_block_content_instead_of_value
    render_inline(Bali::LabelValue::Component.new(label: "URL")) do
      "Custom link content"
    end
    assert_selector("div.min-h-6", text: "Custom link content")
  end

  def test_prefers_value_over_block_content_when_both_provided
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "From value")) do
      "From block"
    end
    assert_selector("div.min-h-6", text: "From value")
    assert_no_text("From block")
  end

  def test_merges_custom_classes
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test", class: "custom-class"))
    assert_selector("div.mb-2.custom-class")
  end

  def test_passes_through_html_attributes
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test", data: { testid: "lv" }))
    assert_selector('[data-testid="lv"]')
  end

  def test_applies_proper_label_styling
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test"))
    assert_selector("label.font-bold.text-xs")
  end

  def test_applies_value_container_styling
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test"))
    assert_selector("div.min-h-6", text: "Test")
  end
end
