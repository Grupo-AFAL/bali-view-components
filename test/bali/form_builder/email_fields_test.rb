# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderEmailFieldsTest < FormBuilderTestCase
  # #email_field_group

  def test_email_field_group_renders_a_fieldset_wrapper
    result = builder.email_field_group(:contact_email)
    assert_html(result, "fieldset.fieldset")
  end

  def test_email_field_group_renders_a_legend_label
    result = builder.email_field_group(:contact_email)
    assert_html(result, "legend.fieldset-legend", text: "Contact email")
  end

  def test_email_field_group_renders_an_email_input_with_correct_attributes
    result = builder.email_field_group(:contact_email)
    assert_html(result, 'input#movie_contact_email[type="email"][name="movie[contact_email]"]')
  end

  def test_email_field_group_applies_daisyui_input_classes
    result = builder.email_field_group(:contact_email)
    assert_html(result, "input.input.input-bordered")
  end

  # #email_field

  def test_email_field_renders_a_div_with_control_class
    result = builder.email_field(:contact_email)
    assert_html(result, "div.control")
  end

  def test_email_field_renders_an_email_input_with_correct_attributes
    result = builder.email_field(:contact_email)
    assert_html(result, 'input#movie_contact_email[type="email"][name="movie[contact_email]"]')
  end

  def test_email_field_applies_daisyui_input_classes
    result = builder.email_field(:contact_email)
    assert_html(result, "input.input.input-bordered")
  end

  def test_email_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.email_field(:contact_email, class: "custom-input")
    assert_html(result, "input.input.input-bordered.custom-input")
  end

  def test_email_field_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:contact_email, "is invalid")
    result = builder.email_field(:contact_email)
    assert_html(result, "input.input.input-error")
  end

  def test_email_field_with_validation_errors_displays_error_message
    resource.errors.add(:contact_email, "is invalid")
    result = builder.email_field(:contact_email)
    assert_html(result, "p.text-error", text: "Contact email is invalid")
  end

  def test_email_field_with_help_text_displays_help_text
    result = builder.email_field(:contact_email, help: "Enter your email")
    assert_html(result, "p.label-text-alt", text: "Enter your email")
  end

  def test_email_field_with_data_attributes_passes_through_data_attributes
    result = builder.email_field(:contact_email, data: { testid: "email-input" })
    assert_html(result, 'input.input[data-testid="email-input"]')
  end

  def test_email_field_with_addon_left_renders_within_a_join_container
    result = builder.email_field(:contact_email, addon_left: builder.content_tag(:span, "@", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_email_field_with_addon_left_applies_join_item_class_to_input
    result = builder.email_field(:contact_email, addon_left: builder.content_tag(:span, "@", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_email_field_with_addon_left_renders_the_addon
    result = builder.email_field(:contact_email, addon_left: builder.content_tag(:span, "@", class: "btn"))
    assert_html(result, "span.btn", text: "@")
  end

  def test_email_field_with_addon_right_renders_within_a_join_container
    result = builder.email_field(:contact_email, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "div.join")
  end

  def test_email_field_with_addon_right_applies_join_item_class_to_input
    result = builder.email_field(:contact_email, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "input.input.join-item")
  end

  def test_email_field_with_addon_right_renders_the_addon
    result = builder.email_field(:contact_email, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "span.btn", text: ".com")
  end

  def test_email_field_with_placeholder_renders_input_with_placeholder
    result = builder.email_field(:contact_email, placeholder: "you@example.com")
    assert_html(result, 'input[placeholder="you@example.com"]')
  end

  def test_email_field_with_required_attribute_renders_required_input
    result = builder.email_field(:contact_email, required: true)
    assert_html(result, "input[required]")
  end

  def test_email_field_with_disabled_attribute_renders_disabled_input
    result = builder.email_field(:contact_email, disabled: true)
    assert_html(result, "input[disabled]")
  end
end
