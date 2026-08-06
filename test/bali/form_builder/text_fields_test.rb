# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderTextFieldsTest < FormBuilderTestCase
  # #text_group

  def test_text_group_renders_a_fieldset_wrapper
    result = builder.text_group(:name)
    assert_html(result, "fieldset.fieldset")
  end

  def test_text_group_renders_a_legend_label
    result = builder.text_group(:name)
    assert_html(result, "label.fieldset-legend", text: "Name")
  end

  def test_text_group_renders_a_text_input_with_correct_attributes
    result = builder.text_group(:name)
    assert_html(result, 'input#movie_name[type="text"][name="movie[name]"]')
  end

  def test_text_group_applies_daisyui_input_classes
    result = builder.text_group(:name)
    assert_html(result, "input.input")
  end

  # #text_field

  def test_text_field_renders_a_div_with_control_class
    result = builder.text_field(:name)
    assert_html(result, "div.control")
  end

  def test_text_field_renders_a_text_input_with_correct_attributes
    result = builder.text_field(:name)
    assert_html(result, 'input#movie_name[type="text"][name="movie[name]"]')
  end

  def test_text_field_applies_daisyui_input_classes
    result = builder.text_field(:name)
    assert_html(result, "input.input")
  end

  def test_text_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.text_field(:name, class: "custom-input")
    assert_html(result, "input.input.custom-input")
  end

  def test_text_field_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:name, "is invalid")
    result = builder.text_field(:name)
    assert_html(result, "input.input.input-error")
  end

  def test_text_field_with_validation_errors_displays_error_message
    resource.errors.add(:name, "is invalid")
    result = builder.text_field(:name)
    assert_html(result, "p.text-error", text: "Name is invalid")
  end

  def test_text_field_with_help_text_displays_help_text
    result = builder.text_field(:name, help: "Enter your name")
    assert_html(result, "p.fieldset-label", text: "Enter your name")
  end

  def test_text_field_with_data_attributes_passes_through_data_attributes
    result = builder.text_field(:name, data: { testid: "name-input" })
    assert_html(result, 'input.input[data-testid="name-input"]')
  end

  def test_text_field_with_addon_left_renders_within_a_join_container
    result = builder.text_field(:name, addon_left: builder.content_tag(:span, "@", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_text_field_with_addon_left_applies_join_item_class_to_input
    result = builder.text_field(:name, addon_left: builder.content_tag(:span, "@", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_text_field_with_addon_left_renders_the_addon
    result = builder.text_field(:name, addon_left: builder.content_tag(:span, "@", class: "btn"))
    assert_html(result, "span.btn", text: "@")
  end

  def test_text_field_with_addon_right_renders_within_a_join_container
    result = builder.text_field(:name, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_text_field_with_addon_right_applies_join_item_class_to_input
    result = builder.text_field(:name, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_text_field_with_addon_right_renders_the_addon
    result = builder.text_field(:name, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "span.btn", text: ".com")
  end

  def test_text_field_with_placeholder_renders_input_with_placeholder
    result = builder.text_field(:name, placeholder: "Enter your name")
    assert_html(result, 'input[placeholder="Enter your name"]')
  end

  def test_text_field_with_required_attribute_renders_required_input
    result = builder.text_field(:name, required: true)
    assert_html(result, "input[required]")
  end

  def test_text_field_with_disabled_attribute_renders_disabled_input
    result = builder.text_field(:name, disabled: true)
    assert_html(result, "input[disabled]")
  end

  # char_counter: (#723). The same wrapper, the same controller and the same
  # counter element the textarea has had since it was a textarea-only option —
  # an `<input>` and a `<textarea>` are the same thing to a controller that only
  # reads `value.length`.

  def test_text_field_with_char_counter_puts_the_controller_on_the_control_div
    result = builder.text_field(:name, char_counter: true)

    assert_html(result, 'div.control[data-controller="textarea"]')
  end

  def test_text_field_with_char_counter_targets_the_input_and_listens_for_typing
    result = builder.text_field(:name, char_counter: true)

    assert_html(result, 'input[data-textarea-target="input"]')
    assert_html(result, 'input[data-action="input->textarea#onInput"]')
  end

  def test_text_field_with_char_counter_renders_the_counter_element
    result = builder.text_field(:name, char_counter: true)

    assert_html(result, 'p.text-end.w-full[data-textarea-target="counter"]')
  end

  def test_text_field_with_char_counter_max_sets_the_max_length_value
    result = builder.text_field(:name, char_counter: { max: 140 })

    assert_html(result, 'div[data-textarea-max-length-value="140"]')
  end

  def test_text_field_without_a_max_leaves_the_counter_unbounded
    result = builder.text_field(:name, char_counter: true)

    assert_html(result, 'div[data-textarea-max-length-value="0"]')
  end

  # The option is Bali's, not an attribute: it must not reach the element.
  def test_text_field_never_emits_char_counter_as_an_attribute
    result = builder.text_field(:name, char_counter: { max: 140 })

    refute_html(result, "input[char_counter]")
    refute_html(result, "input[char-counter]")
  end

  # Auto-grow stays a textarea option — an `<input>` has no height to grow — so
  # a text field's wrapper never claims it.
  def test_text_field_with_char_counter_does_not_ask_for_auto_grow
    result = builder.text_field(:name, char_counter: true)

    assert_html(result, 'div[data-textarea-auto-grow-value="false"]')
  end

  def test_text_field_without_char_counter_stays_a_plain_control_div
    result = builder.text_field(:name)

    assert_html(result, "div.control")
    refute_html(result, "[data-controller]")
    refute_html(result, "[data-textarea-target]")
  end

  # The counter has to live inside the element carrying the controller, so with
  # an addon the join moves into the control div instead of replacing it.
  def test_text_field_with_char_counter_and_an_addon_keeps_both
    result = builder.text_field(
      :name, char_counter: { max: 10 },
      addon_right: builder.content_tag(:span, ".com", class: "btn")
    )

    assert_html(result, 'div.control[data-controller="textarea"] div.join input.join-item')
    assert_html(result, 'div.control p[data-textarea-target="counter"]')
  end

  def test_text_field_with_char_counter_still_renders_its_help_and_error
    resource.errors.add(:name, "is invalid")
    result = builder.text_field(:name, char_counter: true, help: "Keep it short")

    assert_html(result, "p.fieldset-label.text-error")
    assert_html(result, "p.fieldset-label", text: "Keep it short")
  end

  # A call site that wired its own Stimulus action keeps it: the counter's is
  # prepended, not merged over.
  def test_text_field_with_char_counter_keeps_a_call_sites_own_action
    result = builder.text_field(
      :name, char_counter: true, data: { action: "input->other#thing" }
    )

    action = Nokogiri::HTML5.fragment(result.to_s).css("input").first["data-action"]

    assert_includes action, "input->textarea#onInput"
    assert_includes action, "input->other#thing"
  end

  def test_text_group_carries_the_counter_into_its_fieldset
    result = builder.text_group(:name, char_counter: { max: 140 })

    assert_html(result, 'fieldset div.control[data-controller="textarea"]')
    assert_html(result, 'fieldset p[data-textarea-target="counter"]')
  end
end
