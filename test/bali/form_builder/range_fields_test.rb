# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderRangeFieldGroupTest < FormBuilderTestCase
  def test_renders_a_fieldset_wrapper
    result = builder.range_group(:rating)
    assert_html(result, "fieldset.fieldset")
  end

  # Through FieldGroupWrapper now, so the fieldset carries the same derived id
  # every other family's does. The hand-rolled one had none.
  def test_renders_the_fieldset_with_an_id_derived_from_the_field
    assert_html(builder.range_group(:rating), "fieldset#movie_rating_field")
  end

  # Handing `@template.range_field` a bare object name threw away the form
  # index, so two forms for the same model emitted the same id *and* the same
  # name: the caption's `for` pointed at an id nobody emitted, and on submit the
  # second slider's value overwrote the first.
  def test_the_slider_follows_the_form_index
    indexed = Bali::FormBuilder.new("movie", Movie.new, vc_test_controller.view_context, index: 2)
    result = indexed.range_group(:rating)

    assert_html(result, 'input#movie_2_rating[name="movie[2][rating]"]')
    assert_html(result, 'label.fieldset-legend[for="movie_2_rating"]')
  end


  def test_renders_a_caption_labelling_the_slider_with_the_translated_attribute
    result = builder.range_group(:rating)
    assert_html(result, 'fieldset label.fieldset-legend[for="movie_rating"]', text: "Rating")
    assert_html(result, 'input[type="range"]#movie_rating')
  end

  def test_renders_a_range_input
    result = builder.range_group(:rating)
    assert_html(result, 'input[type="range"].range')
  end

  def test_sets_default_min_max_step_values
    result = builder.range_group(:rating)
    assert_html(result, 'input[min="0"][max="100"][step="1"]')
  end

  def test_applies_w_full_class_for_full_width
    result = builder.range_group(:rating)
    assert_html(result, "input.range.w-full")
  end

  # with custom label

  def test_with_custom_label_renders_custom_label_text
    result = builder.range_group(:rating, label: "Custom Label")
    assert_html(result, "label.fieldset-legend", text: "Custom Label")
  end

  # with min, max, step options

  def test_with_min_max_step_options_sets_custom_values
    result = builder.range_group(:rating, min: 10, max: 500, step: 10)
    assert_html(result, 'input[min="10"][max="500"][step="10"]')
  end

  # size variants

  Bali::FormBuilder::RangeFields::SIZES.each do |size, css_class|
    define_method("test_size_#{size}_applies_#{css_class}_class") do
      result = builder.range_group(:rating, size: size)
      assert_html(result, "input.range.#{css_class}")
    end
  end

  # color variants

  Bali::FormBuilder::RangeFields::COLORS.each do |color, css_class|
    define_method("test_color_#{color}_applies_#{css_class}_class") do
      result = builder.range_group(:rating, color: color)
      assert_html(result, "input.range.#{css_class}")
    end
  end

  # with combined size and color

  def test_with_combined_size_and_color_applies_both_classes
    result = builder.range_group(:rating, size: :sm, color: :primary)
    assert_html(result, "input.range.range-sm.range-primary")
  end

  # with show_ticks option

  def test_with_show_ticks_renders_tick_marks_container
    result = builder.range_group(:rating, min: 0, max: 100, show_ticks: true, ticks: 3)
    assert_html(result, "div.flex.justify-between")
  end

  def test_with_show_ticks_renders_tick_labels
    result = builder.range_group(:rating, min: 0, max: 100, show_ticks: true, ticks: 3)
    assert_html(result, "div span", count: 3)
    assert_html(result, "span", text: "0")
    assert_html(result, "span", text: "50")
    assert_html(result, "span", text: "100")
  end

  # with tick_labels option

  def test_with_tick_labels_renders_custom_tick_labels
    result = builder.range_group(:rating, tick_labels: %w[Low Medium High])
    assert_html(result, "span", text: "Low")
    assert_html(result, "span", text: "Medium")
    assert_html(result, "span", text: "High")
  end

  # with prefix and suffix

  def test_with_prefix_and_suffix_renders_tick_labels_with_prefix_and_suffix
    result = builder.range_group(:rating, min: 0, max: 100, show_ticks: true, ticks: 3, prefix: "$", suffix: "k")
    assert_html(result, "span", text: "$0k")
    assert_html(result, "span", text: "$100k")
  end

  # with validation errors

  def test_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:rating, "is invalid")
    result = builder.range_group(:rating)
    assert_html(result, "input.range.range-error")
  end

  def test_with_validation_errors_renders_error_message
    resource.errors.add(:rating, "is invalid")
    result = builder.range_group(:rating)
    assert_html(result, "p.text-error", text: "Rating is invalid")
  end

  # with custom class

  def test_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.range_group(:rating, class: "custom-range")
    assert_html(result, "input.range.custom-range")
  end
end

class BaliFormBuilderRangeFieldTest < FormBuilderTestCase
  def test_renders_just_the_range_input_without_fieldset
    result = builder.range_field(:rating, color: :accent)
    refute_html(result, "fieldset")
    assert_html(result, 'input[type="range"].range.range-accent')
  end
end
