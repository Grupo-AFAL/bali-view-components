# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderDatetimeFieldsTest < FormBuilderTestCase
  # DatetimeFields::DATETIME_WRAPPER_OPTIONS

  def test_datetimefields_datetime_wrapper_options_is_frozen
    assert Bali::FormBuilder::DatetimeFields::DATETIME_WRAPPER_OPTIONS.frozen?
  end

  def test_datetimefields_datetime_wrapper_options_has_enable_time_set_to_true
    assert_equal(
      true,
      Bali::FormBuilder::DatetimeFields::DATETIME_WRAPPER_OPTIONS[:'data-datepicker-enable-time-value']
    )
  end

  # #datetime_field_group

  def test_datetime_field_group_renders_a_label_and_input_within_a_wrapper
    result = builder.datetime_field_group(:release_date)
    assert_html(result, ".fieldset")
  end

  def test_datetime_field_group_renders_a_label
    result = builder.datetime_field_group(:release_date)
    assert_html(result, "legend.fieldset-legend", text: "Release date")
  end

  def test_datetime_field_group_renders_a_field_with_a_datepicker_controller
    result = builder.datetime_field_group(:release_date)
    assert_html(result, '.fieldset[data-controller="datepicker"]')
  end

  def test_datetime_field_group_renders_a_field_with_datepicker_time_enabled
    result = builder.datetime_field_group(:release_date)
    assert_html(result, '.fieldset[data-datepicker-enable-time-value="true"]')
  end

  def test_datetime_field_group_renders_a_field_with_datepicker_locale_value
    result = builder.datetime_field_group(:release_date)
    assert_html(result, '.fieldset[data-datepicker-locale-value="en"]')
  end

  def test_datetime_field_group_renders_an_input
    result = builder.datetime_field_group(:release_date)
    assert_html(result, 'input#movie_release_date[name="movie[release_date]"]')
  end

  # #datetime_select_group

  def test_datetime_select_group_is_an_alias_for_datetime_field_group
    assert_equal(:datetime_field_group, builder.method(:datetime_select_group).original_name)
  end

  # #datetime_field

  def test_datetime_field_renders_a_field_with_a_datepicker_controller
    result = builder.datetime_field(:release_date)
    assert_html(result, '.fieldset[data-controller="datepicker"]')
  end

  def test_datetime_field_renders_a_field_with_datepicker_time_enabled
    result = builder.datetime_field(:release_date)
    assert_html(result, '.fieldset[data-datepicker-enable-time-value="true"]')
  end

  def test_datetime_field_renders_a_field_with_datepicker_locale_value
    result = builder.datetime_field(:release_date)
    assert_html(result, '.fieldset[data-datepicker-locale-value="en"]')
  end

  def test_datetime_field_renders_an_input
    result = builder.datetime_field(:release_date)
    assert_html(result, 'input#movie_release_date[name="movie[release_date]"]')
  end

  def test_datetime_field_does_not_mutate_the_passed_options_hash
    original_options = { class: "my-class" }
    options_copy = original_options.dup
    builder.datetime_field(:release_date, original_options)
    assert_equal(options_copy, original_options)
  end

  def test_datetime_field_with_existing_wrapper_options_merges_with_datetime_wrapper_options
    result = builder.datetime_field(:release_date, wrapper_options: { 'data-custom': "value" })
    assert_html(result, '.fieldset[data-custom="value"]')
    assert_html(result, '.fieldset[data-datepicker-enable-time-value="true"]')
  end
end
