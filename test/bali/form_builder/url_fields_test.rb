# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderUrlFieldsTest < FormBuilderTestCase
  # #url_field_group

  def test_url_field_group_renders_a_fieldset_wrapper
    result = builder.url_field_group(:website_url)
    assert_html(result, "fieldset.fieldset")
  end


  def test_url_field_group_renders_a_legend_label
    result = builder.url_field_group(:website_url)
    assert_html(result, "legend.fieldset-legend", text: "Website url")
  end


  def test_url_field_group_renders_a_url_input_with_correct_attributes
    result = builder.url_field_group(:website_url)
    assert_html(result, 'input#movie_website_url[type="url"][name="movie[website_url]"]')
  end


  def test_url_field_group_applies_daisyui_input_classes
    result = builder.url_field_group(:website_url)
    assert_html(result, "input.input.input-bordered")
  end

  # #url_field

  def test_url_field_renders_a_div_with_control_class
    result = builder.url_field(:website_url)
    assert_html(result, "div.control")
  end


  def test_url_field_renders_a_url_input_with_correct_attributes
    result = builder.url_field(:website_url)
    assert_html(result, 'input#movie_website_url[type="url"][name="movie[website_url]"]')
  end


  def test_url_field_applies_daisyui_input_classes
    result = builder.url_field(:website_url)
    assert_html(result, "input.input.input-bordered")
  end


  def test_url_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.url_field(:website_url, class: "custom-input")
    assert_html(result, "input.input.input-bordered.custom-input")
  end


  def test_url_field_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:website_url, "is invalid")
    result = builder.url_field(:website_url)
    assert_html(result, "input.input.input-error")
  end


  def test_url_field_with_validation_errors_displays_error_message
    resource.errors.add(:website_url, "is invalid")
    result = builder.url_field(:website_url)
    assert_html(result, "p.text-error", text: "Website url is invalid")
  end


  def test_url_field_with_help_text_displays_help_text
    result = builder.url_field(:website_url, help: "Enter website URL")
    assert_html(result, "p.label-text-alt", text: "Enter website URL")
  end


  def test_url_field_with_data_attributes_passes_through_data_attributes
    result = builder.url_field(:website_url, data: { testid: "url-input" })
    assert_html(result, 'input.input[data-testid="url-input"]')
  end


  def test_url_field_with_addon_left_renders_within_a_join_container
    result = builder.url_field(:website_url, addon_left: builder.content_tag(:span, "https://", class: "btn"))
    assert_html(result, "div.join")
  end


  def test_url_field_with_addon_left_applies_join_item_class_to_input
    result = builder.url_field(:website_url, addon_left: builder.content_tag(:span, "https://", class: "btn"))
    assert_html(result, "input.input.join-item")
  end


  def test_url_field_with_addon_left_renders_the_addon
    result = builder.url_field(:website_url, addon_left: builder.content_tag(:span, "https://", class: "btn"))
    assert_html(result, "span.btn", text: "https://")
  end


  def test_url_field_with_addon_left_does_not_wrap_in_control_div_when_addons_present
    result = builder.url_field(:website_url, addon_left: builder.content_tag(:span, "https://", class: "btn"))
    refute_html(result, "div.control")
  end


  def test_url_field_with_addon_right_renders_within_a_join_container
    result = builder.url_field(:website_url, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "div.join")
  end


  def test_url_field_with_addon_right_applies_join_item_class_to_input
    result = builder.url_field(:website_url, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "input.input.join-item")
  end


  def test_url_field_with_addon_right_renders_the_addon
    result = builder.url_field(:website_url, addon_right: builder.content_tag(:span, ".com", class: "btn"))
    assert_html(result, "span.btn", text: ".com")
  end


  def test_url_field_with_placeholder_renders_input_with_placeholder
    result = builder.url_field(:website_url, placeholder: "https://example.com")
    assert_html(result, 'input[placeholder="https://example.com"]')
  end


  def test_url_field_with_required_attribute_renders_required_input
    result = builder.url_field(:website_url, required: true)
    assert_html(result, "input[required]")
  end


  def test_url_field_with_disabled_attribute_renders_disabled_input
    result = builder.url_field(:website_url, disabled: true)
    assert_html(result, "input[disabled]")
  end
end
