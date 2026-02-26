# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderBooleanFieldsTest < FormBuilderTestCase
  # #boolean_field_group

  def test_boolean_field_group_renders_a_fieldset_wrapper
    result = builder.boolean_field_group(:indie)
    assert_html(result, "fieldset.fieldset")
  end

  def test_boolean_field_group_renders_a_legend_label
    result = builder.boolean_field_group(:indie)
    assert_html(result, "legend.fieldset-legend", text: "Indie")
  end

  def test_boolean_field_group_renders_a_label_with_cursor_pointer_class
    result = builder.boolean_field_group(:indie)
    assert_html(result, "label.label.cursor-pointer")
  end

  def test_boolean_field_group_renders_checkbox_with_daisyui_class
    result = builder.boolean_field_group(:indie)
    assert_html(result, 'input.checkbox[type="checkbox"]')
  end

  def test_boolean_field_group_renders_label_text_in_a_span
    result = builder.boolean_field_group(:indie)
    assert_html(result, "span.label-text", text: "Indie")
  end

  def test_boolean_field_group_renders_the_hidden_unchecked_input
    result = builder.boolean_field_group(:indie)
    assert_html(result, 'input[value="0"]', visible: false)
  end

  def test_boolean_field_group_renders_the_checkbox_input_with_correct_id
    result = builder.boolean_field_group(:indie)
    assert_html(result, 'input#movie_indie[value="1"]')
  end

  # #boolean_field

  def test_boolean_field_renders_a_label_with_daisyui_classes
    result = builder.boolean_field(:indie)
    assert_html(result, "label.label.cursor-pointer")
  end

  def test_boolean_field_applies_checkbox_class_to_input
    result = builder.boolean_field(:indie)
    assert_html(result, "input.checkbox")
  end

  def test_boolean_field_renders_label_text_in_a_span_with_label_text_class
    result = builder.boolean_field(:indie)
    assert_html(result, "span.label-text", text: "Indie")
  end

  def test_boolean_field_renders_the_hidden_unchecked_input
    result = builder.boolean_field(:indie)
    assert_html(result, 'input[value="0"]', visible: false)
  end

  def test_boolean_field_renders_the_checkbox_input
    result = builder.boolean_field(:indie)
    assert_html(result, 'input#movie_indie[value="1"]')
  end

  def test_boolean_field_with_custom_label_uses_custom_label_text
    result = builder.boolean_field(:indie, label: "Independent Film")
    assert_html(result, "span.label-text", text: "Independent Film")
  end

  def test_boolean_field_with_label_options_merges_custom_label_classes_with_daisyui_classes
    result = builder.boolean_field(:indie, label_options: { class: "custom-label" })
    assert_html(result, "label.label.cursor-pointer.custom-label")
  end

  def test_boolean_field_with_combined_size_and_color_applies_both_classes
    result = builder.boolean_field(:indie, size: :lg, color: :primary)
    assert_html(result, "input.checkbox.checkbox-lg.checkbox-primary")
  end

  def test_boolean_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.boolean_field(:indie, class: "custom-checkbox")
    assert_html(result, "input.checkbox.custom-checkbox")
  end

  def test_boolean_field_with_validation_errors_applies_error_class_to_checkbox
    resource.errors.add(:indie, "must be accepted")
    result = builder.boolean_field(:indie)
    assert_html(result, "input.checkbox.checkbox-error")
  end

  def test_boolean_field_with_validation_errors_displays_error_message
    resource.errors.add(:indie, "must be accepted")
    result = builder.boolean_field(:indie)
    assert_html(result, "p.text-error", text: "Indie must be accepted")
  end

  def test_boolean_field_with_custom_checked_unchecked_values_uses_custom_unchecked_value
    result = builder.boolean_field(:indie, {}, "yes", "no")
    assert_html(result, 'input[value="no"]', visible: false)
  end

  def test_boolean_field_with_custom_checked_unchecked_values_uses_custom_checked_value
    result = builder.boolean_field(:indie, {}, "yes", "no")
    assert_html(result, 'input[value="yes"]')
  end

  def test_boolean_field_with_additional_html_attributes_passes_through_data_attributes
    result = builder.boolean_field(:indie, data: { testid: "indie-checkbox" })
    assert_html(result, 'input.checkbox[data-testid="indie-checkbox"]')
  end

  # size variants
  Bali::FormBuilder::BooleanFields::SIZES.each do |size, css_class|
    define_method("test_boolean_field_size_#{size}_applies_#{css_class.tr("-", "_")}_class") do
      result = builder.boolean_field(:indie, size: size)
      assert_html(result, "input.checkbox.#{css_class}")
    end
  end

  # color variants
  Bali::FormBuilder::BooleanFields::COLORS.each do |color, css_class|
    define_method("test_boolean_field_color_#{color}_applies_#{css_class.tr("-", "_")}_class") do
      result = builder.boolean_field(:indie, color: color)
      assert_html(result, "input.checkbox.#{css_class}")
    end
  end

  # #check_box_group alias

  def test_check_box_group_is_an_alias_for_boolean_field_group
    assert_equal(builder.method(:boolean_field_group), builder.method(:check_box_group))
  end
end
