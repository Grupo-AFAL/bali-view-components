# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderSwitchFieldGroupTest < FormBuilderTestCase
  # #switch_group

  def test_renders_a_fieldset_wrapper
    result = builder.switch_group(:indie)
    assert_includes(result, "fieldset")
    assert_includes(result, "fieldset")
  end

  def test_renders_a_label_with_cursor_pointer_class
    assert_includes(builder.switch_group(:indie), "cursor-pointer")
  end

  def test_renders_toggle_with_daisyui_class
    assert_includes(builder.switch_group(:indie), "toggle")
  end

  def test_renders_label_text_in_a_span
    assert_includes(builder.switch_group(:indie), "Indie")
  end

  def test_renders_the_hidden_unchecked_input
    assert_includes(builder.switch_group(:indie), 'value="0"')
  end

  def test_renders_the_toggle_input_with_correct_id
    assert_includes(builder.switch_group(:indie), 'id="movie_indie"')
  end

  # Through FieldGroupWrapper now, which is where the fieldset's own id comes
  # from. The hand-rolled `<fieldset class="fieldset">` had none, so two toggles
  # for the same model on one page were indistinguishable.
  def test_renders_the_fieldset_with_an_id_derived_from_the_field
    assert_html(builder.switch_group(:indie), "fieldset#movie_indie_field.fieldset")
  end

  def test_renders_no_legend_by_default
    refute_html(builder.switch_group(:indie), "legend.fieldset-legend")
  end

  def test_names_the_attribute_exactly_once
    assert_html(builder.switch_group(:indie), "span", text: "Indie", count: 1)
  end

  def test_renders_a_legend_when_asked_for_one
    result = builder.switch_group(:indie, label: "Distribution")
    assert_html(result, "legend.fieldset-legend", text: "Distribution")
    assert_html(result, "label.label span", text: "Indie")
  end
end

class BaliFormBuilderSwitchFieldTest < FormBuilderTestCase
  # #switch_field

  def test_renders_a_label_with_daisyui_classes
    result = builder.switch_field(:indie)
    assert_includes(result, "label")
    assert_includes(result, "cursor-pointer")
  end

  def test_applies_toggle_class_to_input
    assert_includes(builder.switch_field(:indie), "toggle")
  end

  def test_renders_label_text_in_a_span_with_label_text_class
    assert_includes(builder.switch_field(:indie), "Indie")
  end

  def test_renders_the_hidden_unchecked_input
    assert_includes(builder.switch_field(:indie), 'value="0"')
  end

  def test_renders_the_toggle_input
    assert_includes(builder.switch_field(:indie), 'id="movie_indie"')
  end
  # with custom label

  # `text:`, not `label:` — same split as BooleanFields.
  def test_with_custom_text_uses_it_beside_the_toggle
    assert_html(builder.switch_field(:indie, text: "Independent Film"),
                "label.label span", text: "Independent Film")
  end

  def test_with_text_false_renders_no_caption_beside_the_toggle
    refute_html(builder.switch_field(:indie, text: false), "label.label span")
  end

  def test_does_not_leak_text_onto_the_toggle
    refute_html(builder.switch_field(:indie, text: "Independent Film"), "input[text]")
  end
  # with label_options

  def test_with_label_options_merges_custom_label_classes_with_daisyui_classes
    result = builder.switch_field(:indie, label_options: { class: "custom-label" })
    assert_includes(result, "custom-label")
    assert_includes(result, "cursor-pointer")
  end
  # size variants

  def test_size_variants
    Bali::FormBuilder::SwitchFields::SIZES.each do |size, css_class|
      result = builder.switch_field(:indie, size: size)
      assert_includes(result, css_class, "Expected size #{size} to produce class #{css_class}")
    end
  end

  # color variants

  def test_color_variants
    Bali::FormBuilder::SwitchFields::COLORS.each do |color, css_class|
      result = builder.switch_field(:indie, color: color)
      assert_includes(result, css_class, "Expected color #{color} to produce class #{css_class}")
    end
  end

  # with combined size and color

  def test_with_combined_size_and_color_applies_both_size_and_color_classes
    result = builder.switch_field(:indie, size: :lg, color: :primary)
    assert_includes(result, "toggle-lg")
    assert_includes(result, "toggle-primary")
  end
  # with custom class

  def test_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.switch_field(:indie, class: "custom-toggle")
    assert_includes(result, "custom-toggle")
    assert_includes(result, "toggle")
  end
  # with validation errors

  def test_with_validation_errors_applies_error_class_to_toggle
    resource.errors.add(:indie, "must be accepted")
    result = builder.switch_field(:indie)
    assert_includes(result, "toggle-error")
  end

  def test_with_validation_errors_displays_error_message
    resource.errors.add(:indie, "must be accepted")
    result = builder.switch_field(:indie)
    assert_includes(result, "Indie must be accepted")
  end
  # with custom checked/unchecked values

  def test_with_custom_checked_unchecked_values_uses_custom_unchecked_value
    assert_includes(builder.switch_field(:indie, checked_value: "yes", unchecked_value: "no"), 'value="no"')
  end

  def test_with_custom_checked_unchecked_values_uses_custom_checked_value
    assert_includes(builder.switch_field(:indie, checked_value: "yes", unchecked_value: "no"), 'value="yes"')
  end
  # with additional HTML attributes

  def test_with_additional_html_attributes_passes_through_data_attributes
    result = builder.switch_field(:indie, data: { testid: "indie-toggle" })
    assert_includes(result, 'data-testid="indie-toggle"')
  end
end
