# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderFileFieldsTest < FormBuilderTestCase
  # #file_field_group

  def test_file_field_group_renders_a_div_with_a_file_input_controller
    result = builder.file_field_group(:cover_photo)
    assert_html(result,
                'div.flex[data-controller="file-input"]' \
                '[data-file-input-non-selected-text-value="No file selected"]')
  end

  def test_file_field_group_renders_an_input_with_a_data_action
    result = builder.file_field_group(:cover_photo)
    assert_html(result, 'input#movie_cover_photo[name="movie[cover_photo]"][data-action="file-input#onChange"]')
  end

  def test_file_field_group_renders_a_label_with_cursor_pointer_class
    result = builder.file_field_group(:cover_photo)
    assert_html(result, "label.cursor-pointer")
  end

  def test_file_field_group_renders_an_icon
    result = builder.file_field_group(:cover_photo)
    assert_html(result, "span.icon-component")
  end

  def test_file_field_group_renders_with_hidden_class_on_the_input_hidden_but_accessible
    result = builder.file_field_group(:cover_photo)
    assert_html(result, "input.hidden")
  end

  def test_file_field_group_renders_the_cta_button_with_proper_classes
    result = builder.file_field_group(:cover_photo)
    assert_html(result, "span.btn.btn-soft.btn-primary.btn-sm.gap-2")
  end

  def test_file_field_group_renders_the_filename_display_with_truncate_class
    result = builder.file_field_group(:cover_photo)
    assert_html(result, "span.truncate")
  end

  def test_file_field_group_renders_filename_display_outside_the_label
    result = builder.file_field_group(:cover_photo)
    assert_html(result, "div > label + span.truncate")
  end

  # #file_field

  def test_file_field_renders_an_input
    result = builder.file_field(:cover_photo)
    assert_html(result, 'input#movie_cover_photo[name="movie[cover_photo]"]')
  end

  def test_file_field_renders_with_hidden_class_hidden_but_accessible
    result = builder.file_field(:cover_photo)
    assert_html(result, "input.hidden")
  end

  # customization options

  def test_customization_options_accepts_custom_choose_file_text
    result = builder.file_field(:cover_photo, choose_file_text: "Upload Image")
    assert_html(result, "span", text: "Upload Image")
  end

  def test_customization_options_accepts_custom_non_selected_text
    result = builder.file_field(:cover_photo, non_selected_text: "No image")
    assert_html(result, "span", text: "No image")
    assert_html(result, '[data-file-input-non-selected-text-value="No image"]')
  end

  def test_customization_options_hides_label_when_choose_file_text_is_false
    result = builder.file_field(:cover_photo, choose_file_text: false)
    assert_html(result, "span.btn.btn-soft span.icon-component")
    refute_html(result, "span.btn.btn-soft > span:not(.icon-component)")
  end

  def test_customization_options_accepts_custom_icon
    result = builder.file_field(:cover_photo, icon: "camera")
    assert_html(result, "span.icon-component")
  end

  def test_customization_options_accepts_file_class_for_wrapper_styling
    result = builder.file_field(:cover_photo, file_class: "custom-wrapper")
    assert_html(result, "div.custom-wrapper")
  end

  def test_customization_options_preserves_wrapper_base_classes_when_file_class_is_provided
    result = builder.file_field(:cover_photo, file_class: "custom-wrapper")
    assert_html(result, "div.flex.custom-wrapper")
  end

  # multiple file selection

  def test_multiple_file_selection_sets_multiple_attribute_on_input
    result = builder.file_field(:cover_photo, multiple: true)
    assert_html(result, "input[multiple]")
  end

  def test_multiple_file_selection_passes_multiple_value_to_stimulus_controller
    result = builder.file_field(:cover_photo, multiple: true)
    assert_html(result, '[data-file-input-multiple-value="true"]')
  end

  def test_multiple_file_selection_sets_multiple_value_to_false_by_default
    result = builder.file_field(:cover_photo)
    assert_html(result, '[data-file-input-multiple-value="false"]')
  end

  # HTML attributes passthrough

  def test_html_attributes_passthrough_accepts_accept_attribute_for_file_types
    result = builder.file_field(:cover_photo, accept: ".jpg,.png")
    assert_html(result, 'input[accept=".jpg,.png"]')
  end

  def test_html_attributes_passthrough_accepts_required_attribute
    result = builder.file_field(:cover_photo, required: true)
    assert_html(result, "input[required]")
  end

  def test_html_attributes_passthrough_accepts_custom_data_attributes
    result = builder.file_field(:cover_photo, data: { testid: "file-upload" })
    assert_html(result, 'input[data-testid="file-upload"]')
  end

  def test_html_attributes_passthrough_keeps_input_hidden_even_with_custom_class_option
    result = builder.file_field(:cover_photo, class: "custom-input")
    assert_html(result, "input.hidden")
  end

  # i18n

  def test_i18n_uses_translated_choose_file_text_by_default
    I18n.with_locale(:en) do
      result = builder.file_field(:cover_photo)
      assert_html(result, "span", text: "Choose file")
    end
  end

  def test_i18n_uses_translated_non_selected_text_by_default
    I18n.with_locale(:en) do
      result = builder.file_field(:cover_photo)
      assert_html(result, "span", text: "No file selected")
    end
  end

  def test_i18n_supports_spanish_locale
    I18n.with_locale(:es) do
      result = builder.file_field(:cover_photo)
      assert_html(result, "span", text: "Seleccionar archivo")
      assert_html(result, "span", text: "Ningún archivo seleccionado")
    end
  end

  # constants

  def test_constants_has_input_class_constant_hidden_for_accessibility
    assert_equal "hidden", Bali::FormBuilder::FileFields::INPUT_CLASS
  end

  def test_constants_has_wrapper_class_constant
    assert_equal "flex items-center gap-3", Bali::FormBuilder::FileFields::WRAPPER_CLASS
  end

  def test_constants_has_filename_class_constant
    assert_equal "text-sm text-base-content/60 truncate", Bali::FormBuilder::FileFields::FILENAME_CLASS
  end

  def test_constants_has_cta_class_constant
    assert_equal "btn btn-soft btn-primary btn-sm gap-2", Bali::FormBuilder::FileFields::CTA_CLASS
  end

  def test_constants_has_label_class_constant
    assert_equal "cursor-pointer inline-flex", Bali::FormBuilder::FileFields::LABEL_CLASS
  end

  def test_constants_has_default_icon_constant
    assert_equal "upload", Bali::FormBuilder::FileFields::DEFAULT_ICON
  end
end
