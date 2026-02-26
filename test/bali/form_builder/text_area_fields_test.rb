# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderTextAreaFieldsTest < FormBuilderTestCase
  # #text_area_group

  def test_text_area_group_renders_a_fieldset_wrapper
    result = builder.text_area_group(:synopsis)
    assert_html(result, "fieldset.fieldset")
  end


  def test_text_area_group_renders_a_legend_label
    result = builder.text_area_group(:synopsis)
    assert_html(result, "legend.fieldset-legend", text: "Synopsis")
  end


  def test_text_area_group_renders_a_text_area_with_correct_name
    result = builder.text_area_group(:synopsis)
    assert_html(result, 'textarea#movie_synopsis[name="movie[synopsis]"]')
  end


  def test_text_area_group_applies_daisyui_textarea_classes
    result = builder.text_area_group(:synopsis)
    assert_html(result, "textarea.textarea.textarea-bordered")
  end

  # #text_area

  def test_text_area_renders_a_control_wrapper
    result = builder.text_area(:synopsis)
    assert_html(result, "div.control")
  end


  def test_text_area_renders_a_text_area_element
    result = builder.text_area(:synopsis)
    assert_html(result, 'textarea#movie_synopsis[name="movie[synopsis]"]')
  end


  def test_text_area_applies_daisyui_textarea_classes
    result = builder.text_area(:synopsis)
    assert_html(result, "textarea.textarea.textarea-bordered.w-full")
  end


  def test_text_area_with_custom_class_merges_custom_classes
    result = builder.text_area(:synopsis, class: "min-h-32")
    assert_html(result, "textarea.textarea.textarea-bordered.min-h-32")
  end


  def test_text_area_with_validation_errors_applies_error_class
    resource.errors.add(:synopsis, "is required")
    result = builder.text_area(:synopsis)
    assert_html(result, "textarea.input-error")
  end


  def test_text_area_with_validation_errors_displays_error_message
    resource.errors.add(:synopsis, "is required")
    result = builder.text_area(:synopsis)
    assert_html(result, "p.text-error", text: "Synopsis is required")
  end


  def test_text_area_with_help_text_displays_help_text
    result = builder.text_area(:synopsis, help: "Enter a brief synopsis")
    assert_html(result, "p.label-text-alt", text: "Enter a brief synopsis")
  end


  def test_text_area_with_rows_option_applies_rows_attribute
    result = builder.text_area(:synopsis, rows: 5)
    assert_html(result, 'textarea[rows="5"]')
  end


  def test_text_area_with_placeholder_applies_placeholder_attribute
    result = builder.text_area(:synopsis, placeholder: "Enter synopsis...")
    assert_html(result, 'textarea[placeholder="Enter synopsis..."]')
  end


  def test_text_area_with_char_counter_true_wraps_textarea_in_stimulus_controller_div_with_control_class
    result = builder.text_area(:synopsis, char_counter: true)
    assert_html(result, 'div.control[data-controller="textarea"]')
  end


  def test_text_area_with_char_counter_true_adds_textarea_target_to_input
    result = builder.text_area(:synopsis, char_counter: true)
    assert_html(result, 'textarea[data-textarea-target="input"]')
  end


  def test_text_area_with_char_counter_true_adds_input_action_to_textarea
    result = builder.text_area(:synopsis, char_counter: true)
    assert_html(result, 'textarea[data-action="input->textarea#onInput"]')
  end


  def test_text_area_with_char_counter_true_renders_counter_element
    result = builder.text_area(:synopsis, char_counter: true)
    assert_html(result, 'p[data-textarea-target="counter"]')
  end


  def test_text_area_with_char_counter_true_sets_max_length_value_to_0_when_no_max_provided
    result = builder.text_area(:synopsis, char_counter: true)
    assert_html(result, 'div[data-textarea-max-length-value="0"]')
  end


  def test_text_area_with_char_counter_max_500_sets_max_length_value_from_options
    result = builder.text_area(:synopsis, char_counter: { max: 500 })
    assert_html(result, 'div[data-textarea-max-length-value="500"]')
  end


  def test_text_area_with_char_counter_max_500_renders_counter_element_with_alignment_classes
    result = builder.text_area(:synopsis, char_counter: { max: 500 })
    assert_html(result, 'p.label-text-alt.text-end.w-full[data-textarea-target="counter"]')
  end


  def test_text_area_with_auto_grow_true_wraps_textarea_in_stimulus_controller_div
    result = builder.text_area(:synopsis, auto_grow: true)
    assert_html(result, 'div[data-controller="textarea"]')
  end


  def test_text_area_with_auto_grow_true_sets_auto_grow_value_to_true
    result = builder.text_area(:synopsis, auto_grow: true)
    assert_html(result, 'div[data-textarea-auto-grow-value="true"]')
  end


  def test_text_area_with_auto_grow_true_adds_textarea_target_to_input
    result = builder.text_area(:synopsis, auto_grow: true)
    assert_html(result, 'textarea[data-textarea-target="input"]')
  end


  def test_text_area_with_auto_grow_true_does_not_render_counter_element
    result = builder.text_area(:synopsis, auto_grow: true)
    refute_html(result, '[data-textarea-target="counter"]')
  end


  def test_text_area_with_both_char_counter_and_auto_grow_wraps_textarea_in_stimulus_controller_div
    result = builder.text_area(:synopsis, char_counter: { max: 200 }, auto_grow: true)
    assert_html(result, 'div[data-controller="textarea"]')
  end


  def test_text_area_with_both_char_counter_and_auto_grow_sets_both_values
    result = builder.text_area(:synopsis, char_counter: { max: 200 }, auto_grow: true)
    assert_html(result, 'div[data-textarea-max-length-value="200"][data-textarea-auto-grow-value="true"]')
  end


  def test_text_area_with_both_char_counter_and_auto_grow_renders_counter_element
    result = builder.text_area(:synopsis, char_counter: { max: 200 }, auto_grow: true)
    assert_html(result, 'p[data-textarea-target="counter"]')
  end
end
