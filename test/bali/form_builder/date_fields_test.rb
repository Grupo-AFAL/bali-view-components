# frozen_string_literal: true

require "test_helper"

class Bali_FormBuilder_DateFieldsTest < FormBuilderTestCase
  # #date_field_group

  def test_date_field_group_renders_a_label_and_input_within_a_wrapper
    result = builder.date_field_group(:release_date)
    assert_html(result, "fieldset.fieldset")
  end

  def test_date_field_group_renders_a_label
    result = builder.date_field_group(:release_date)
    assert_html(result, "legend.fieldset-legend", text: "Release date")
  end

  def test_date_field_group_renders_a_field_with_datepicker_controller
    result = builder.date_field_group(:release_date)
    assert_html(result, 'div[data-controller="datepicker"]')
  end

  def test_date_field_group_renders_a_field_with_datepicker_locale_value
    result = builder.date_field_group(:release_date)
    assert_html(result, 'div[data-datepicker-locale-value="en"]')
  end

  def test_date_field_group_renders_an_input
    result = builder.date_field_group(:release_date)
    assert_html(result, 'input#movie_release_date[name="movie[release_date]"]')
  end

  def test_date_field_group_with_clear_option_renders_a_clear_button
    result = builder.date_field_group(:release_date, clear: true)
    assert_html(result, 'button[data-action="datepicker#clear"]')
  end

  def test_date_field_group_with_clear_option_clear_button_has_aria_label
    result = builder.date_field_group(:release_date, clear: true)
    assert_html(result, 'button[aria-label="Clear date"]')
  end

  def test_date_field_group_with_clear_option_renders_clear_icon
    result = builder.date_field_group(:release_date, clear: true)
    assert_html(result, "button span.icon-component")
  end

  def test_date_field_group_with_manual_mode_renders_a_join_wrapper
    result = builder.date_field_group(:release_date, manual: true)
    assert_html(result, "div.fieldset.flatpickr.join")
  end

  def test_date_field_group_with_manual_mode_renders_a_previous_date_button
    result = builder.date_field_group(:release_date, manual: true)
    assert_html(result, 'button[data-action="datepicker#previousDate"]')
  end

  def test_date_field_group_with_manual_mode_renders_a_next_date_button
    result = builder.date_field_group(:release_date, manual: true)
    assert_html(result, 'button[data-action="datepicker#nextDate"]')
  end

  def test_date_field_group_with_manual_mode_previous_button_has_aria_label
    result = builder.date_field_group(:release_date, manual: true)
    assert_html(result, 'button[aria-label="Previous date"]')
  end

  def test_date_field_group_with_manual_mode_next_button_has_aria_label
    result = builder.date_field_group(:release_date, manual: true)
    assert_html(result, 'button[aria-label="Next date"]')
  end

  def test_date_field_group_with_manual_mode_buttons_have_daisyui_classes
    result = builder.date_field_group(:release_date, manual: true)
    assert_html(result, "button.btn.btn-ghost.join-item", count: 2)
  end

  def test_date_field_group_with_min_date_option_passes_min_date_to_datepicker_controller
    result = builder.date_field_group(:release_date, min_date: "2024-01-01")
    assert_html(result, 'div[data-datepicker-min-date-value="2024-01-01"]')
  end

  def test_date_field_group_with_max_date_option_passes_max_date_to_datepicker_controller
    result = builder.date_field_group(:release_date, max_date: "2024-12-31")
    assert_html(result, 'div[data-datepicker-max-date-value="2024-12-31"]')
  end

  def test_date_field_group_with_disable_weekends_option_passes_disable_weekends_to_datepicker_controller
    result = builder.date_field_group(:release_date, disable_weekends: true)
    assert_html(result, 'div[data-datepicker-disable-weekends-value="true"]')
  end

  def test_date_field_group_with_range_mode_passes_mode_to_datepicker_controller
    result = builder.date_field_group(:release_date, mode: "range")
    assert_html(result, 'div[data-datepicker-mode-value="range"]')
  end

  def test_date_field_group_with_range_mode_and_default_values_passes_default_dates_to_datepicker_controller
    result = builder.date_field_group(:release_date, mode: "range", value: %w[2024-01-01 2024-01-31])
    assert_html(result, "div[data-datepicker-default-dates-value]")
  end

  def test_date_field_group_with_period_option_passes_period_to_datepicker_controller
    result = builder.date_field_group(:release_date, period: "day")
    assert_html(result, 'div[data-datepicker-period-value="day"]')
  end

  def test_date_field_group_with_custom_wrapper_options_merges_custom_wrapper_options
    result = builder.date_field_group(:release_date, wrapper_options: { class: "custom-wrapper" })
    assert_html(result, 'div.custom-wrapper[data-controller="datepicker"]')
  end

  # #month_field_group

  def test_month_field_group_renders_a_fieldset_wrapper
    result = builder.month_field_group(:release_date)
    assert_html(result, "fieldset.fieldset")
  end

  def test_month_field_group_renders_a_month_input
    result = builder.month_field_group(:release_date)
    assert_html(result, 'input[type="month"]')
  end

  # #month_field

  def test_month_field_renders_a_month_input
    result = builder.month_field(:release_date)
    assert_html(result, 'input[type="month"]')
  end

  def test_month_field_applies_daisyui_input_classes
    result = builder.month_field(:release_date)
    assert_html(result, "input.input.input-bordered")
  end

  # constants

  def test_constants_defines_wrapper_class
    assert_equal("fieldset flatpickr", Bali::FormBuilder::SharedDateUtils::WRAPPER_CLASS)
  end

  def test_constants_defines_button_class
    assert_equal("btn btn-ghost", Bali::FormBuilder::SharedDateUtils::BUTTON_CLASS)
  end

  def test_constants_defines_join_item_class
    assert_equal("join-item", Bali::FormBuilder::SharedDateUtils::JOIN_ITEM_CLASS)
  end

  def test_constants_freezes_wrapper_class
    assert Bali::FormBuilder::SharedDateUtils::WRAPPER_CLASS.frozen?
  end

  def test_constants_freezes_button_class
    assert Bali::FormBuilder::SharedDateUtils::BUTTON_CLASS.frozen?
  end
end
