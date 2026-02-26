# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderPasswordFieldsTest < FormBuilderTestCase
  # #password_field_group

  def test_password_field_group_renders_a_fieldset_wrapper
    result = builder.password_field_group(:budget)
    assert_html(result, "fieldset.fieldset")
  end

  def test_password_field_group_renders_a_legend_label
    result = builder.password_field_group(:budget)
    assert_html(result, "legend.fieldset-legend", text: "Budget")
  end

  def test_password_field_group_renders_a_password_input_with_correct_attributes
    result = builder.password_field_group(:budget)
    assert_html(result, 'input#movie_budget[type="password"][name="movie[budget]"]')
  end

  def test_password_field_group_applies_daisyui_input_classes
    result = builder.password_field_group(:budget)
    assert_html(result, "input.input.input-bordered")
  end

  # #password_field

  def test_password_field_renders_a_div_with_control_class
    result = builder.password_field(:budget)
    assert_html(result, "div.control")
  end

  def test_password_field_renders_a_password_input_with_correct_attributes
    result = builder.password_field(:budget)
    assert_html(result, 'input#movie_budget[type="password"][name="movie[budget]"]')
  end

  def test_password_field_applies_daisyui_input_classes
    result = builder.password_field(:budget)
    assert_html(result, "input.input.input-bordered")
  end

  def test_password_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.password_field(:budget, class: "custom-input")
    assert_html(result, "input.input.input-bordered.custom-input")
  end

  def test_password_field_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:budget, "is required")
    result = builder.password_field(:budget)
    assert_html(result, "input.input.input-error")
  end

  def test_password_field_with_validation_errors_displays_error_message
    resource.errors.add(:budget, "is required")
    result = builder.password_field(:budget)
    assert_html(result, "p.text-error", text: "Budget is required")
  end

  def test_password_field_with_help_text_displays_help_text
    result = builder.password_field(:budget, help: "Minimum 8 characters")
    assert_html(result, "p.label-text-alt", text: "Minimum 8 characters")
  end

  def test_password_field_with_data_attributes_passes_through_data_attributes
    result = builder.password_field(:budget, data: { testid: "password-input" })
    assert_html(result, 'input.input[data-testid="password-input"]')
  end

  def test_password_field_with_addon_left_renders_within_a_join_container
    result = builder.password_field(:budget, addon_left: builder.content_tag(:span, "Lock", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_password_field_with_addon_left_applies_join_item_class_to_input
    result = builder.password_field(:budget, addon_left: builder.content_tag(:span, "Lock", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_password_field_with_addon_left_renders_the_addon
    result = builder.password_field(:budget, addon_left: builder.content_tag(:span, "Lock", class: "btn"))
    assert_html(result, "span.btn", text: "Lock")
  end

  def test_password_field_with_addon_right_renders_within_a_join_container
    result = builder.password_field(:budget, addon_right: builder.content_tag(:button, "Show", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_password_field_with_addon_right_applies_join_item_class_to_input
    result = builder.password_field(:budget, addon_right: builder.content_tag(:button, "Show", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_password_field_with_addon_right_renders_the_addon
    result = builder.password_field(:budget, addon_right: builder.content_tag(:button, "Show", class: "btn"))
    assert_html(result, "button.btn", text: "Show")
  end

  def test_password_field_with_placeholder_renders_input_with_placeholder
    result = builder.password_field(:budget, placeholder: "Enter password")
    assert_html(result, 'input[placeholder="Enter password"]')
  end

  def test_password_field_with_required_attribute_renders_required_input
    result = builder.password_field(:budget, required: true)
    assert_html(result, "input[required]")
  end

  def test_password_field_with_disabled_attribute_renders_disabled_input
    result = builder.password_field(:budget, disabled: true)
    assert_html(result, "input[disabled]")
  end
end
