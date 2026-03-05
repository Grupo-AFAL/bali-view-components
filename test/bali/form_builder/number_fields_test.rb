# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderNumberFieldsTest < FormBuilderTestCase
  # #number_field_group

  def test_number_field_group_renders_a_fieldset_wrapper
    result = builder.number_field_group(:budget)
    assert_html(result, "fieldset.fieldset")
  end

  def test_number_field_group_renders_a_legend_label
    result = builder.number_field_group(:budget)
    assert_html(result, "legend.fieldset-legend", text: "Budget")
  end

  def test_number_field_group_renders_a_number_input_with_correct_attributes
    result = builder.number_field_group(:budget)
    assert_html(result, 'input#movie_budget[type="number"][name="movie[budget]"]')
  end

  def test_number_field_group_applies_daisyui_input_classes
    result = builder.number_field_group(:budget)
    assert_html(result, "input.input.input-bordered")
  end

  # #number_field

  def test_number_field_renders_a_div_with_control_class
    result = builder.number_field(:budget)
    assert_html(result, "div.control")
  end

  def test_number_field_renders_a_number_input_with_correct_attributes
    result = builder.number_field(:budget)
    assert_html(result, 'input#movie_budget[type="number"][name="movie[budget]"]')
  end

  def test_number_field_applies_daisyui_input_classes
    result = builder.number_field(:budget)
    assert_html(result, "input.input.input-bordered")
  end

  def test_number_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.number_field(:budget, class: "custom-input")
    assert_html(result, "input.input.input-bordered.custom-input")
  end

  def test_number_field_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:budget, "must be positive")
    result = builder.number_field(:budget)
    assert_html(result, "input.input.input-error")
  end

  def test_number_field_with_validation_errors_displays_error_message
    resource.errors.add(:budget, "must be positive")
    result = builder.number_field(:budget)
    assert_html(result, "p.text-error", text: "Budget must be positive")
  end

  def test_number_field_with_help_text_displays_help_text
    result = builder.number_field(:budget, help: "Enter amount in dollars")
    assert_html(result, "p.label-text-alt", text: "Enter amount in dollars")
  end

  def test_number_field_with_data_attributes_passes_through_data_attributes
    result = builder.number_field(:budget, data: { testid: "budget-input" })
    assert_html(result, 'input.input[data-testid="budget-input"]')
  end

  def test_number_field_with_addon_left_renders_within_a_join_container
    result = builder.number_field(:budget, addon_left: builder.content_tag(:span, "$", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_number_field_with_addon_left_applies_join_item_class_to_input
    result = builder.number_field(:budget, addon_left: builder.content_tag(:span, "$", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_number_field_with_addon_left_renders_the_addon
    result = builder.number_field(:budget, addon_left: builder.content_tag(:span, "$", class: "btn"))
    assert_html(result, "span.btn", text: "$")
  end

  def test_number_field_with_addon_right_renders_within_a_join_container
    result = builder.number_field(:budget, addon_right: builder.content_tag(:span, "USD", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_number_field_with_addon_right_applies_join_item_class_to_input
    result = builder.number_field(:budget, addon_right: builder.content_tag(:span, "USD", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_number_field_with_addon_right_renders_the_addon
    result = builder.number_field(:budget, addon_right: builder.content_tag(:span, "USD", class: "btn"))
    assert_html(result, "span.btn", text: "USD")
  end

  def test_number_field_with_min_and_max_renders_input_with_min_and_max_attributes
    result = builder.number_field(:budget, min: 0, max: 1_000_000)
    assert_html(result, 'input[min="0"][max="1000000"]')
  end

  def test_number_field_with_step_renders_input_with_step_attribute
    result = builder.number_field(:budget, step: 0.01)
    assert_html(result, 'input[step="0.01"]')
  end

  def test_number_field_with_placeholder_renders_input_with_placeholder
    result = builder.number_field(:budget, placeholder: "0.00")
    assert_html(result, 'input[placeholder="0.00"]')
  end

  def test_number_field_with_required_attribute_renders_required_input
    result = builder.number_field(:budget, required: true)
    assert_html(result, "input[required]")
  end

  def test_number_field_with_disabled_attribute_renders_disabled_input
    result = builder.number_field(:budget, disabled: true)
    assert_html(result, "input[disabled]")
  end
end
