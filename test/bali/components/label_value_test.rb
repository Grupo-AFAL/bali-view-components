# frozen_string_literal: true

require "test_helper"

class BaliLabelValueComponentTest < ComponentTestCase
  def test_renders_with_label_and_value
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Juan Perez"))
    assert_selector("dt", text: "Name")
    assert_selector("dd.min-h-6", text: "Juan Perez")
  end

  def test_renders_with_block_content_instead_of_value
    render_inline(Bali::LabelValue::Component.new(label: "URL")) do
      "Custom link content"
    end
    assert_selector("dd.min-h-6", text: "Custom link content")
  end

  def test_prefers_value_over_block_content_when_both_provided
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "From value")) do
      "From block"
    end
    assert_selector("dd.min-h-6", text: "From value")
    assert_no_text("From block")
  end

  def test_merges_custom_classes
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test", class: "custom-class"))
    assert_selector("dl.mb-2.custom-class")
  end

  def test_passes_through_html_attributes
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test", data: { testid: "lv" }))
    assert_selector('[data-testid="lv"]')
  end

  def test_applies_proper_label_styling
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test"))
    assert_selector("dt.font-bold.text-xs")
  end

  def test_applies_value_container_styling
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Test"))
    assert_selector("dd.min-h-6", text: "Test")
  end

  # The `<label>` this used to render pointed at no control, so the term and the
  # value beside it were two unrelated nodes. A one-pair `<dl>` is the pairing
  # the markup already meant, and it needs no ARIA to say so.
  def test_a11y_pairs_the_term_with_its_value_in_a_description_list
    render_inline(Bali::LabelValue::Component.new(label: "Name", value: "Juan Perez"))
    assert_selector("dl > dt", text: "Name")
    assert_selector("dl > dd", text: "Juan Perez")
    assert_no_selector("label")
  end
end
