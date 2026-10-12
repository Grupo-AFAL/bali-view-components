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
    assert_html(result, "label.fieldset-legend", text: "Synopsis")
  end

  def test_text_area_group_renders_a_text_area_with_correct_name
    result = builder.text_area_group(:synopsis)
    assert_html(result, 'textarea#movie_synopsis[name="movie[synopsis]"]')
  end

  def test_text_area_group_applies_daisyui_textarea_classes
    result = builder.text_area_group(:synopsis)
    assert_html(result, "textarea.textarea")
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
    assert_html(result, "textarea.textarea.w-full")
  end

  def test_text_area_with_custom_class_merges_custom_classes
    result = builder.text_area(:synopsis, class: "min-h-32")
    assert_html(result, "textarea.textarea.min-h-32")
  end

  def test_text_area_with_validation_errors_applies_error_class
    resource.errors.add(:synopsis, "is required")
    result = builder.text_area(:synopsis)
    assert_html(result, "textarea.textarea-error")
  end

  def test_text_area_with_validation_errors_displays_error_message
    resource.errors.add(:synopsis, "is required")
    result = builder.text_area(:synopsis)
    assert_html(result, "p.text-soft-error", text: "Synopsis is required")
  end

  def test_text_area_with_help_text_displays_help_text
    result = builder.text_area(:synopsis, help: "Enter a brief synopsis")
    assert_html(result, "p.fieldset-label", text: "Enter a brief synopsis")
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
    assert_html(result, 'p.text-end.w-full[data-textarea-target="counter"]')
  end

  def test_text_area_with_char_counter_still_renders_its_help_and_error
    resource.errors.add(:synopsis, "is required")
    result = builder.text_area(:synopsis, char_counter: { max: 500 }, help: "Keep it short")

    assert_html(result, "p.text-soft-error", text: "Synopsis is required")
    assert_html(result, "p.fieldset-label", text: "Keep it short")
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

  # Dictation (#1450). The whole point of the option is that the call site stops hand-wiring six
  # attributes across three elements: forgetting one of them is not visible when you try it.

  def test_text_area_with_dictation_puts_the_controller_on_the_control_box
    result = builder.text_area(:synopsis, dictation: true)
    assert_html(result, 'div.control[data-controller~="speech-input"]')
  end

  def test_text_area_with_dictation_makes_the_textarea_its_subject
    result = builder.text_area(:synopsis, dictation: true)
    assert_html(result, 'textarea[data-speech-input-target="input"]')
  end

  # Half the feature: without it the next result rebuilds the field from what was there when the
  # mic went on, and eats the correction just typed.
  def test_text_area_with_dictation_stops_the_mic_on_a_keystroke
    result = builder.text_area(:synopsis, dictation: true)
    assert_html(result, 'textarea[data-action~="input->speech-input#typed"]')
  end

  # Born hidden, and NOT rendered absent: `speech-input` reveals it only where the browser has
  # recognition, so the markup cannot promise what the browser cannot do.
  # `visible: :all` on both: they are rendered `hidden`, and Capybara's default scope would not
  # find them — which is the assertion, so it is spelled out rather than worked around.
  def test_text_area_with_dictation_renders_the_button_hidden
    result = builder.text_area(:synopsis, dictation: true)
    assert_html(result, 'button[type="button"][hidden][data-speech-input-target="button"]', visible: :all)
    assert_html(result, 'button[data-action="speech-input#toggle"][aria-pressed="false"]', visible: :all)
    refute_html(result, "button[data-speech-input-target]")
  end

  def test_text_area_with_dictation_renders_the_status_line_hidden
    result = builder.text_area(:synopsis, dictation: true)
    assert_html(result, 'p[role="status"][hidden][data-speech-input-target="status"]', visible: :all)
    refute_html(result, 'p[data-speech-input-target="status"]')
  end

  def test_text_area_with_dictation_leaves_room_for_the_button_under_the_last_line
    result = builder.text_area(:synopsis, dictation: true)
    assert_html(result, "div.control.relative")
    assert_html(result, "textarea.pb-12")
  end

  def test_text_area_with_dictation_hash_carries_the_language
    result = builder.text_area(:synopsis, dictation: { lang: "en-US" })
    assert_html(result, 'div[data-speech-input-lang-value="en-US"]')
  end

  # No language is not the empty string: the controller's own default answers for it.
  def test_text_area_with_dictation_true_leaves_the_language_to_the_controller
    result = builder.text_area(:synopsis, dictation: true)
    refute_html(result, "div[data-speech-input-lang-value]")
  end

  def test_text_area_without_dictation_carries_no_trace_of_it
    result = builder.text_area(:synopsis, auto_grow: true)
    refute_html(result, '[data-controller~="speech-input"]')
    refute_html(result, "[data-speech-input-target]")
    refute_html(result, "textarea.pb-12")
  end

  # The two share the control box, and neither may evict the other: before #1450 the counter
  # wrote `controller:` flat, so whatever was already there went silently.
  def test_text_area_with_dictation_and_auto_grow_carries_both_controllers
    result = builder.text_area(:synopsis, char_counter: { max: 200 }, auto_grow: true, dictation: true)
    assert_html(result, 'div[data-controller~="textarea"][data-controller~="speech-input"]')
    assert_html(result, 'textarea[data-textarea-target="input"][data-speech-input-target="input"]')
    assert_html(result, 'textarea[data-action~="input->textarea#onInput"]')
    assert_html(result, 'textarea[data-action~="input->speech-input#typed"]')
  end

  # `dictation:` is Bali's, not an attribute: Rails forwards whatever it does not recognise.
  def test_text_area_does_not_forward_dictation_onto_the_element
    result = builder.text_area(:synopsis, dictation: true)
    refute_html(result, "textarea[dictation]")
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
