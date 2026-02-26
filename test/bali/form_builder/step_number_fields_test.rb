# frozen_string_literal: true

require "test_helper"

class Bali_FormBuilder_StepNumberFieldsTest < FormBuilderTestCase
  # #step_number_field_group

  def test_step_number_field_group_renders_the_input_and_label_within_a_wrapper
    result = builder.step_number_field_group(:duration)
    assert_html(result, "#field-duration.fieldset")
  end

  def test_step_number_field_group_renders_the_label
    result = builder.step_number_field_group(:duration)
    assert_html(result, "legend.fieldset-legend", text: "Duration")
  end

  def test_step_number_field_group_renders_the_input
    result = builder.step_number_field_group(:duration)
    assert_html(result, 'input#movie_duration[name="movie[duration]"]')
  end

  # #step_number_field

  def test_step_number_field_renders_the_field_with_the_step_number_input_controller
    result = builder.step_number_field(:duration)
    assert_html(result, '.join[data-controller="step-number-input"]')
  end

  # subtract button

  def test_step_number_field_subtract_button_renders_with_correct_stimulus_action
    result = builder.step_number_field(:duration)
    assert_html(result, 'button[data-action*="step-number-input#subtract"]')
  end

  def test_step_number_field_subtract_button_renders_with_correct_stimulus_target
    result = builder.step_number_field(:duration)
    assert_html(result, 'button[data-step-number-input-target="subtract"]')
  end

  def test_step_number_field_subtract_button_renders_with_aria_label_for_accessibility
    result = builder.step_number_field(:duration)
    assert_html(result, 'button[aria-label="Decrease value"]')
  end

  def test_step_number_field_subtract_button_renders_with_daisyui_button_classes
    result = builder.step_number_field(:duration)
    assert_html(result, "button.btn.join-item")
  end

  def test_step_number_field_subtract_button_renders_with_minus_icon
    result = builder.step_number_field(:duration)
    assert_html(result, "button span.icon-component svg.lucide-icon")
  end

  # input field

  def test_step_number_field_input_field_renders_with_correct_target_attribute
    result = builder.step_number_field(:duration)
    assert_html(result, 'input[data-step-number-input-target="input"]')
  end

  def test_step_number_field_input_field_renders_with_daisyui_input_classes
    result = builder.step_number_field(:duration)
    assert_html(result, "input.input.input-bordered.join-item")
  end

  def test_step_number_field_input_field_renders_with_correct_name_and_id
    result = builder.step_number_field(:duration)
    assert_html(result, '#movie_duration[name="movie[duration]"]')
  end

  def test_step_number_field_input_field_applies_text_center_class_for_alignment
    result = builder.step_number_field(:duration)
    assert_html(result, "input.text-center")
  end

  # add button

  def test_step_number_field_add_button_renders_with_correct_stimulus_action
    result = builder.step_number_field(:duration)
    assert_html(result, 'button[data-action*="step-number-input#add"]')
  end

  def test_step_number_field_add_button_renders_with_correct_stimulus_target
    result = builder.step_number_field(:duration)
    assert_html(result, 'button[data-step-number-input-target="add"]')
  end

  def test_step_number_field_add_button_renders_with_aria_label_for_accessibility
    result = builder.step_number_field(:duration)
    assert_html(result, 'button[aria-label="Increase value"]')
  end

  def test_step_number_field_add_button_renders_with_plus_icon
    result = builder.step_number_field(:duration)
    assert_html(result, "button span.icon-component svg.lucide-icon")
  end

  # disabled

  def test_step_number_field_when_disabled_renders_disabled_buttons_with_btn_disabled_class
    result = builder.step_number_field(:duration, disabled: true)
    assert_html(result, "button.btn-disabled.pointer-events-none[disabled]", count: 2)
  end

  def test_step_number_field_when_disabled_does_not_add_data_actions_to_disabled_buttons
    result = builder.step_number_field(:duration, disabled: true)
    refute_html(result, "button[disabled][data-action]")
  end

  def test_step_number_field_when_disabled_renders_disabled_input
    result = builder.step_number_field(:duration, disabled: true)
    assert_html(result, "input[disabled]")
  end

  # custom button class

  def test_step_number_field_with_custom_button_class_applies_the_custom_class_to_both_buttons
    result = builder.step_number_field(:duration, button_class: "btn-primary")
    assert_html(result, "button.btn.btn-primary", count: 2)
  end

  # custom data attributes

  def test_step_number_field_with_custom_data_attributes_merges_subtract_data_attributes
    result = builder.step_number_field(:duration,
                                       subtract_data: { turbo_frame: "_top" },
                                       add_data: { confirm: "Sure?" })
    assert_html(result, 'button[data-turbo-frame="_top"]')
  end

  def test_step_number_field_with_custom_data_attributes_merges_add_data_attributes
    result = builder.step_number_field(:duration,
                                       subtract_data: { turbo_frame: "_top" },
                                       add_data: { confirm: "Sure?" })
    assert_html(result, 'button[data-confirm="Sure?"]')
  end

  def test_step_number_field_with_custom_data_attributes_preserves_stimulus_actions_when_merging
    result = builder.step_number_field(:duration, subtract_data: { turbo_frame: "_top" })
    assert_html(result, 'button[data-turbo-frame="_top"][data-action*="step-number-input#subtract"]')
  end

  # memoization

  def test_step_number_field_when_called_multiple_times_renders_each_field_independently
    first_field = builder.step_number_field(:duration, button_class: "btn-primary")
    second_field = builder.step_number_field(:duration, button_class: "btn-secondary")
    assert_html(first_field, "button.btn-primary", count: 2)
    assert_html(second_field, "button.btn-secondary", count: 2)
    refute_html(second_field, "button.btn-primary")
  end

  def test_step_number_field_does_not_carry_over_subtract_data_between_calls
    first_field = builder.step_number_field(:duration, subtract_data: { custom: "first" })
    second_field = builder.step_number_field(:duration)
    assert_html(first_field, 'button[data-custom="first"]')
    refute_html(second_field, "button[data-custom]")
  end

  # min, max, step

  def test_step_number_field_with_min_max_and_step_attributes_passes_min_attribute_to_the_input
    result = builder.step_number_field(:duration, min: 0, max: 100, step: 5)
    assert_html(result, 'input[min="0"]')
  end

  def test_step_number_field_with_min_max_and_step_attributes_passes_max_attribute_to_the_input
    result = builder.step_number_field(:duration, min: 0, max: 100, step: 5)
    assert_html(result, 'input[max="100"]')
  end

  def test_step_number_field_with_min_max_and_step_attributes_passes_step_attribute_to_the_input
    result = builder.step_number_field(:duration, min: 0, max: 100, step: 5)
    assert_html(result, 'input[step="5"]')
  end

  # custom input class

  def test_step_number_field_with_custom_input_class_appends_custom_class_to_default_input_classes
    result = builder.step_number_field(:duration, class: "w-20")
    assert_html(result, "input.input.input-bordered.join-item.w-20")
  end

  # value

  def test_step_number_field_with_value_sets_the_value_on_the_input
    result = builder.step_number_field(:duration, value: 42)
    assert_html(result, 'input[value="42"]')
  end

  # constants

  def test_constants_defines_frozen_button_base_classes_constant
    assert Bali::FormBuilder::StepNumberFields::BUTTON_BASE_CLASSES.frozen?
    assert_equal "btn join-item", Bali::FormBuilder::StepNumberFields::BUTTON_BASE_CLASSES
  end

  def test_constants_defines_frozen_button_disabled_classes_constant
    assert Bali::FormBuilder::StepNumberFields::BUTTON_DISABLED_CLASSES.frozen?
    assert_equal "btn-disabled pointer-events-none", Bali::FormBuilder::StepNumberFields::BUTTON_DISABLED_CLASSES
  end

  def test_constants_defines_frozen_input_classes_constant
    assert Bali::FormBuilder::StepNumberFields::INPUT_CLASSES.frozen?
    assert_includes Bali::FormBuilder::StepNumberFields::INPUT_CLASSES, "input input-bordered join-item text-center"
    assert_includes Bali::FormBuilder::StepNumberFields::INPUT_CLASSES, "[appearance:textfield]"
  end
end
