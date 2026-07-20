# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderTimeFieldsTest < FormBuilderTestCase
  # TimeFields constants

  def test_timefields_constants_defines_time_wrapper_options
    assert_equal(
      { 'data-datepicker-enable-time-value': true, 'data-datepicker-no-calendar-value': true },
      Bali::FormBuilder::TimeFields::TIME_WRAPPER_OPTIONS
    )
  end

  def test_timefields_constants_freezes_time_wrapper_options
    assert Bali::FormBuilder::TimeFields::TIME_WRAPPER_OPTIONS.frozen?
  end

  def test_timefields_constants_defines_option_to_data_attribute_mapping
    assert_equal(
      {
        seconds: "data-datepicker-enable-seconds-value",
        time_24hr: "data-datepicker-time24hr-value",
        default_date: "data-datepicker-default-date-value",
        min_time: "data-datepicker-min-time-value",
        max_time: "data-datepicker-max-time-value"
      },
      Bali::FormBuilder::TimeFields::OPTION_TO_DATA_ATTRIBUTE
    )
  end

  def test_timefields_constants_freezes_option_to_data_attribute
    assert Bali::FormBuilder::TimeFields::OPTION_TO_DATA_ATTRIBUTE.frozen?
  end

  # #time_field_group

  def test_time_field_group_renders_the_input_and_label_within_a_wrapper
    result = builder.time_field_group(:duration)
    assert_html(result, "#field-duration.fieldset")
  end

  def test_time_field_group_renders_the_label
    result = builder.time_field_group(:duration)
    assert_html(result, "legend.fieldset-legend", text: "Duration")
  end

  def test_time_field_group_renders_the_input
    result = builder.time_field_group(:duration)
    assert_html(result, 'input#movie_duration[name="movie[duration]"]')
  end

  # #time_field

  def test_time_field_renders_the_field_with_the_datepicker_controller
    result = builder.time_field(:duration)
    assert_html(result, '.fieldset[data-controller="datepicker"]')
  end

  def test_time_field_renders_the_input
    result = builder.time_field(:duration)
    assert_html(result, 'input#movie_duration[name="movie[duration]"]')
  end

  def test_time_field_renders_with_datepicker_time_enabled
    result = builder.time_field(:duration)
    assert_html(result, '.fieldset[data-datepicker-enable-time-value="true"]')
  end

  def test_time_field_renders_with_datepicker_calendar_disabled
    result = builder.time_field(:duration)
    assert_html(result, '.fieldset[data-datepicker-no-calendar-value="true"]')
  end

  def test_time_field_renders_with_datepicker_seconds_enabled
    result = builder.time_field(:duration, seconds: true)
    assert_html(result, '.fieldset[data-datepicker-enable-seconds-value="true"]')
  end

  def test_time_field_renders_with_datepicker_default_date
    result = builder.time_field(:duration, default_date: "1983-04-13")
    assert_html(result, '.fieldset[data-datepicker-default-date-value="1983-04-13"]')
  end

  def test_time_field_renders_with_datepicker_min_time
    result = builder.time_field(:duration, min_time: "08:00")
    assert_html(result, '.fieldset[data-datepicker-min-time-value="08:00"]')
  end

  def test_time_field_renders_with_datepicker_max_time
    result = builder.time_field(:duration, max_time: "23:00")
    assert_html(result, '.fieldset[data-datepicker-max-time-value="23:00"]')
  end

  def test_time_field_renders_with_24_hour_time_format
    result = builder.time_field(:duration, time_24hr: true)
    assert_html(result, '.fieldset[data-datepicker-time24hr-value="true"]')
  end

  def test_time_field_with_existing_wrapper_options_merges_with_time_wrapper_options
    result = builder.time_field(:duration, wrapper_options: { 'data-custom': "value" })
    assert_html(result, '.fieldset[data-custom="value"]')
    assert_html(result, '.fieldset[data-datepicker-enable-time-value="true"]')
  end

  def test_time_field_does_not_mutate_input_options_preserves_original_options_hash
    original_options = { seconds: true }
    options_copy = original_options.dup
    builder.time_field(:duration, original_options)
    assert_equal(options_copy, original_options)
  end

  # #time_field_group allow_input

  def test_time_field_group_without_allow_input_option_does_not_render_allow_input_attribute
    result = builder.time_field_group(:duration)
    refute_html(result, "[data-datepicker-allow-input-value]")
  end

  def test_time_field_group_without_allow_input_option_does_not_render_a_placeholder_attribute
    result = builder.time_field_group(:duration)
    refute_html(result, "input[placeholder]")
  end

  def test_time_field_group_with_allow_input_option_renders_allow_input_attribute
    result = builder.time_field_group(:duration, allow_input: true)
    assert_html(result, '.fieldset[data-datepicker-allow-input-value="true"]')
  end

  def test_time_field_group_with_allow_input_and_explicit_alt_format_sets_a_token_mapped_placeholder
    result = builder.time_field_group(:duration, allow_input: true, alt_format: "H:i")
    assert_html(result, 'input[placeholder="HH:MM"]')
  end

  def test_time_field_group_with_allow_input_and_no_alt_format_sets_a_token_mapped_placeholder
    result = builder.time_field_group(:duration, allow_input: true)
    assert_html(result, 'input[placeholder="hh:MM AM/PM"]')
  end

  def test_time_field_group_with_allow_input_and_24_hour_format_maps_the_24_hour_placeholder
    result = builder.time_field_group(:duration, allow_input: true, time_24hr: true)
    assert_html(result, 'input[placeholder="HH:MM"]')
  end

  def test_time_field_group_with_allow_input_and_seconds_maps_the_seconds_token_in_the_placeholder
    result = builder.time_field_group(:duration, allow_input: true, seconds: true)
    assert_html(result, 'input[placeholder="hh:MM:ss AM/PM"]')
  end

  def test_time_field_group_with_allow_input_and_seconds_and_24_hour_format_maps_both_tokens
    result = builder.time_field_group(:duration, allow_input: true, seconds: true, time_24hr: true)
    assert_html(result, 'input[placeholder="HH:MM:ss"]')
  end

  def test_time_field_group_with_allow_input_and_explicit_placeholder_keeps_the_explicit_placeholder
    result = builder.time_field_group(:duration, allow_input: true, placeholder: "Type a time")
    assert_html(result, 'input[placeholder="Type a time"]')
  end
end
