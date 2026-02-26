# frozen_string_literal: true

require "test_helper"

class Bali_FormBuilder_RadioFieldsTest < FormBuilderTestCase
  # #radio_field_group

  def test_radio_field_group_renders_a_label_and_input_within_a_control
    result = builder.radio_field_group(:status, Movie.statuses.to_a)
    assert_html(result, "div.control")
  end

  def test_radio_field_group_renders_a_label_and_input_for_each_option
    result = builder.radio_field_group(:status, Movie.statuses.to_a)
    Movie.statuses.each_value do |value|
      assert_html(result, "label[for=\"movie_status_#{value}\"]")
      assert_html(result, "input#movie_status_#{value}[value=\"#{value}\"]")
    end
  end

  def test_radio_field_group_renders_radio_inputs_with_daisyui_radio_class
    result = builder.radio_field_group(:status, Movie.statuses.to_a)
    assert_html(result, "input.radio")
  end

  def test_radio_field_group_renders_labels_with_cursor_pointer_class
    result = builder.radio_field_group(:status, Movie.statuses.to_a)
    assert_html(result, "label.label.cursor-pointer")
  end

  def test_radio_field_group_renders_display_text_in_span_with_label_text_class
    result = builder.radio_field_group(:status, Movie.statuses.to_a)
    assert_html(result, "span.label-text")
  end

  # #radio_field

  def test_radio_field_renders_radio_inputs_for_each_value
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values)
    assert_html(result, 'input[type="radio"]', count: 3)
  end

  def test_radio_field_renders_labels_with_correct_for_attributes
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values)
    assert_html(result, 'label[for="movie_status_1"]')
    assert_html(result, 'label[for="movie_status_2"]')
    assert_html(result, 'label[for="movie_status_3"]')
  end

  def test_radio_field_with_size_option_applies_size_class_to_radio_inputs
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values, {}, { size: :lg })
    assert_html(result, "input.radio.radio-lg", count: 3)
  end

  def test_radio_field_with_color_option_applies_color_class_to_radio_inputs
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values, {}, { color: :primary })
    assert_html(result, "input.radio.radio-primary", count: 3)
  end

  def test_radio_field_with_custom_label_class_appends_custom_class_to_labels
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values, {}, { radio_label_class: "custom-label" })
    assert_html(result, "label.label.cursor-pointer.custom-label", count: 3)
  end

  def test_radio_field_with_custom_input_class_appends_custom_class_to_radio_inputs
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values, {}, { class: "custom-input" })
    assert_html(result, "input.radio.custom-input", count: 3)
  end

  def test_radio_field_with_vertical_orientation_default_renders_container_with_flex_col_class
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values)
    assert_html(result, "div.flex.flex-col.gap-1")
  end

  def test_radio_field_with_horizontal_orientation_renders_container_with_flex_row_class
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values, {}, { orientation: :horizontal })
    assert_html(result, "div.flex.flex-row.flex-wrap")
  end

  def test_radio_field_with_shared_data_attributes_applies_shared_data_attributes_to_all_radio_inputs
    values = [ %w[One 1], %w[Two 2], %w[Three 3] ]
    result = builder.radio_field(:status, values, {}, { data: { action: "change->form#submit" } })
    assert_html(result, 'input[data-action="change->form#submit"]', count: 3)
  end

  def test_radio_field_with_per_item_custom_data_attributes_applies_custom_data_to_individual_radio_inputs
    values = [
      [ "One", "1", { data: { price: "100" } } ],
      [ "Two", "2", { data: { price: "200" } } ],
      %w[Three 3]
    ]
    result = builder.radio_field(:status, values)
    assert_html(result, 'input[data-price="100"]', count: 1)
    assert_html(result, 'input[data-price="200"]', count: 1)
  end

  def test_radio_field_with_per_item_custom_data_attributes_does_not_add_data_to_items_without_custom_data
    values = [
      [ "One", "1", { data: { price: "100" } } ],
      [ "Two", "2", { data: { price: "200" } } ],
      %w[Three 3]
    ]
    result = builder.radio_field(:status, values)
    refute_html(result, 'input[value="3"][data-price]')
  end

  def test_radio_field_with_shared_and_per_item_data_attributes_merged_merges_shared_data_with_per_item_data
    values = [
      [ "One", "1", { data: { price: "100" } } ],
      %w[Two 2]
    ]
    result = builder.radio_field(:status, values, {}, { data: { controller: "pricing" } })
    assert_html(result, 'input[data-controller="pricing"][data-price="100"]', count: 1)
  end

  def test_radio_field_with_shared_and_per_item_data_attributes_merged_applies_shared_data_to_items_without_custom_data
    values = [
      [ "One", "1", { data: { price: "100" } } ],
      %w[Two 2]
    ]
    result = builder.radio_field(:status, values, {}, { data: { controller: "pricing" } })
    assert_html(result, 'input[value="2"][data-controller="pricing"]')
  end

  # ORIENTATIONS constant

  def test_orientations_constant_includes_vertical_and_horizontal_options
    assert_equal %i[vertical horizontal].sort, Bali::FormBuilder::RadioFields::ORIENTATIONS.keys.sort
  end

  def test_orientations_constant_maps_vertical_to_flex_col_layout
    assert_includes Bali::FormBuilder::RadioFields::ORIENTATIONS[:vertical], "flex-col"
  end

  def test_orientations_constant_maps_horizontal_to_flex_row_layout
    assert_includes Bali::FormBuilder::RadioFields::ORIENTATIONS[:horizontal], "flex-row"
  end

  def test_orientations_constant_is_frozen
    assert Bali::FormBuilder::RadioFields::ORIENTATIONS.frozen?
  end

  # SIZES constant

  def test_sizes_constant_includes_all_daisyui_radio_sizes
    assert_equal %i[xs sm md lg].sort, Bali::FormBuilder::RadioFields::SIZES.keys.sort
  end

  def test_sizes_constant_maps_to_correct_daisyui_classes
    assert_equal "radio-xs", Bali::FormBuilder::RadioFields::SIZES[:xs]
    assert_equal "radio-lg", Bali::FormBuilder::RadioFields::SIZES[:lg]
  end

  def test_sizes_constant_is_frozen
    assert Bali::FormBuilder::RadioFields::SIZES.frozen?
  end

  # COLORS constant

  def test_colors_constant_includes_all_daisyui_radio_colors
    expected = %i[primary secondary accent success warning info error].sort
    assert_equal expected, Bali::FormBuilder::RadioFields::COLORS.keys.sort
  end

  def test_colors_constant_maps_to_correct_daisyui_classes
    assert_equal "radio-primary", Bali::FormBuilder::RadioFields::COLORS[:primary]
    assert_equal "radio-error", Bali::FormBuilder::RadioFields::COLORS[:error]
  end

  def test_colors_constant_is_frozen
    assert Bali::FormBuilder::RadioFields::COLORS.frozen?
  end

  # class constants

  def test_class_constants_defines_radio_class
    assert_equal "radio", Bali::FormBuilder::RadioFields::RADIO_CLASS
  end

  def test_class_constants_defines_label_class_with_cursor_pointer_and_spacing
    assert_equal "label cursor-pointer justify-start gap-3", Bali::FormBuilder::RadioFields::LABEL_CLASS
  end

  def test_class_constants_defines_label_text_class
    assert_equal "label-text", Bali::FormBuilder::RadioFields::LABEL_TEXT_CLASS
  end

  def test_class_constants_defines_error_class
    assert_equal "label-text-alt text-error", Bali::FormBuilder::RadioFields::ERROR_CLASS
  end

  def test_class_constants_defines_controller_name
    assert_equal "radio-buttons-group", Bali::FormBuilder::RadioFields::CONTROLLER_NAME
  end
end
