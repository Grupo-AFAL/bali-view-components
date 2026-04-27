# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderSelectFieldsTest < FormBuilderTestCase
  # #select_group

  def test_select_group_renders_a_label_and_input_within_a_wrapper
    result = builder.select_group(:status, Movie.statuses.to_a)
    assert_html(result, "fieldset.fieldset")
  end

  def test_select_group_renders_a_label
    result = builder.select_group(:status, Movie.statuses.to_a)
    assert_html(result, "legend.fieldset-legend", text: "Status")
  end

  def test_select_group_renders_a_select_with_daisyui_classes
    result = builder.select_group(:status, Movie.statuses.to_a)
    assert_html(result, "select.select.select-bordered.w-full#movie_status")
  end

  def test_select_group_renders_all_options
    result = builder.select_group(:status, Movie.statuses.to_a)
    Movie.statuses.each do |name, value|
      assert_html(result, "option[value=\"#{value}\"]", text: name)
    end
  end

  # #select_field

  def test_select_field_renders_a_div_with_control_class
    result = builder.select_field(:status, Movie.statuses.to_a)
    assert_html(result, "div.control")
  end

  def test_select_field_renders_a_select_with_daisyui_classes
    result = builder.select_field(:status, Movie.statuses.to_a)
    assert_html(result, "select.select.select-bordered.w-full#movie_status")
  end

  def test_select_field_renders_all_options
    result = builder.select_field(:status, Movie.statuses.to_a)
    Movie.statuses.each do |name, value|
      assert_html(result, "option[value=\"#{value}\"]", text: name)
    end
  end

  def test_select_field_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.select_field(:status, Movie.statuses.to_a, {}, class: "custom-class")
    assert_html(result, "select.select.select-bordered.w-full.custom-class")
  end

  def test_select_field_with_validation_errors_renders_select_with_error_class
    resource.errors.add(:status, :invalid)
    result = builder.select_field(:status, Movie.statuses.to_a)
    assert_html(result, "select.select.select-bordered.w-full.select-error")
  end

  def test_select_field_with_validation_errors_displays_error_message
    resource.errors.add(:status, :invalid)
    result = builder.select_field(:status, Movie.statuses.to_a)
    assert_html(result, "p.text-error")
  end

  def test_select_field_with_help_text_displays_help_text
    result = builder.select_field(:status, Movie.statuses.to_a, {}, help: "Select a status")
    assert_html(result, "p.label-text-alt", text: "Select a status")
  end

  # BASE_CLASSES constant

  def test_base_classes_constant_is_frozen
    assert Bali::FormBuilder::SelectFields::BASE_CLASSES.frozen?
  end

  def test_base_classes_constant_contains_daisyui_select_classes
    assert_equal "select select-bordered w-full", Bali::FormBuilder::SelectFields::BASE_CLASSES
  end
end
