# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderTimePeriodFieldsTest < FormBuilderTestCase
  # constants

  def test_constants_has_frozen_controller_name
    assert Bali::FormBuilder::TimePeriodFields::CONTROLLER_NAME.frozen?
    assert_equal "time-period-field", Bali::FormBuilder::TimePeriodFields::CONTROLLER_NAME
  end

  def test_constants_has_frozen_select_classes_with_daisyui_styling
    assert Bali::FormBuilder::TimePeriodFields::SELECT_CLASSES.frozen?
    assert_equal "select select-bordered w-full", Bali::FormBuilder::TimePeriodFields::SELECT_CLASSES
  end

  def test_constants_has_frozen_select_wrapper_classes
    assert Bali::FormBuilder::TimePeriodFields::SELECT_WRAPPER_CLASSES.frozen?
    assert_equal "mb-2", Bali::FormBuilder::TimePeriodFields::SELECT_WRAPPER_CLASSES
  end

  def test_constants_has_frozen_date_field_hidden_class
    assert Bali::FormBuilder::TimePeriodFields::DATE_FIELD_HIDDEN_CLASS.frozen?
    assert_equal "hidden", Bali::FormBuilder::TimePeriodFields::DATE_FIELD_HIDDEN_CLASS
  end

  # #time_period_field_group

  def test_time_period_field_group_renders_within_a_fieldgroupwrapper
    select_options = [ [ "This week", Time.zone.now.all_week ] ]
    result = builder.time_period_field_group(:release_date, select_options)
    assert_html(result, "fieldset.fieldset")
  end

  def test_time_period_field_group_renders_a_legend_with_label
    select_options = [ [ "This week", Time.zone.now.all_week ] ]
    result = builder.time_period_field_group(:release_date, select_options)
    assert_html(result, "legend.fieldset-legend", text: "Release date")
  end

  def test_time_period_field_group_renders_the_time_period_field_inside
    select_options = [ [ "This week", Time.zone.now.all_week ] ]
    result = builder.time_period_field_group(:release_date, select_options)
    assert_html(result, "select.select.select-bordered.w-full")
  end

  # #time_period_field

  def test_time_period_field_renders_a_wrapper_div_with_stimulus_controller
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'div[data-controller="time-period-field"]')
  end

  def test_time_period_field_renders_a_hidden_input_for_the_value
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'input[type="hidden"][name="movie[release_date]"]', visible: false)
  end

  def test_time_period_field_renders_hidden_input_with_stimulus_target
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'input[type="hidden"][data-time-period-field-target="input"]', visible: false)
  end

  def test_time_period_field_renders_a_select_dropdown
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, "select.select.select-bordered.w-full")
  end

  def test_time_period_field_renders_select_with_proper_name
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'select[name="release_date_period"]')
  end

  def test_time_period_field_renders_select_with_stimulus_target
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'select[data-time-period-field-target="select"]')
  end

  def test_time_period_field_renders_select_with_toggle_date_input_action
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'select[data-action*="time-period-field#toggleDateInput"]')
  end

  def test_time_period_field_renders_select_with_set_input_value_action
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'select[data-action*="time-period-field#setInputValue"]')
  end

  def test_time_period_field_renders_all_provided_options_this_week
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, "option", text: "This week")
  end

  def test_time_period_field_renders_all_provided_options_last_week
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, "option", text: "Last week")
  end

  def test_time_period_field_renders_select_wrapper_with_margin_class
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, "div.mb-2 select")
  end

  def test_time_period_field_with_include_blank_option_adds_blank_option_at_the_end
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options, include_blank: "Custom")
    assert_html(result, "option", text: "Custom")
  end

  def test_time_period_field_with_include_blank_does_not_mutate_the_original_select_options_array
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    original_length = select_options.length
    builder.time_period_field(:release_date, select_options, include_blank: "Custom")
    assert_equal original_length, select_options.length
  end

  def test_time_period_field_with_selected_value_matching_an_option_pre_selects_the_matching_option
    selected = Time.zone.now.all_week
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options, selected: selected)
    assert_html(result, "option[selected]", text: "This week")
  end

  def test_time_period_field_with_selected_value_sets_the_hidden_input_value
    selected = Time.zone.now.all_week
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options, selected: selected)
    assert_html(result, 'input[type="hidden"][value]', visible: false)
  end

  def test_time_period_field_with_custom_date_range_does_not_select_any_dropdown_option
    custom_range = 3.days.ago.all_day
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options, selected: custom_range)
    refute_html(result, "option[selected]")
  end

  def test_time_period_field_with_custom_date_range_shows_the_custom_range_in_the_date_field
    custom_range = 3.days.ago.all_day
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options, selected: custom_range)
    assert_html(result, 'input[name="movie[release_date_date_range]"]', visible: false)
  end

  def test_time_period_field_with_object_value_fallback_uses_object_method_value
    resource.release_date = Time.zone.now.all_week.to_s
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'input[type="hidden"]', visible: false)
  end

  def test_time_period_field_date_field_renders_a_date_range_input
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'input[name="movie[release_date_date_range]"]', visible: false)
  end

  def test_time_period_field_date_field_has_hidden_class_by_default
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, "input.hidden", visible: false)
  end

  def test_time_period_field_date_field_has_proper_stimulus_target
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'input[data-time-period-field-target="dateInput"]', visible: false)
  end

  def test_time_period_field_date_field_has_stimulus_action_for_value_updates
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    result = builder.time_period_field(:release_date, select_options)
    assert_html(result, 'input[data-action*="time-period-field#setInputValue"]', visible: false)
  end

  def test_time_period_field_does_not_mutate_options_hash
    select_options = [ [ "This week", Time.zone.now.all_week ], [ "Last week", 1.week.ago.all_week ] ]
    options = { include_blank: "Custom", class: "extra" }
    original_options = options.dup
    builder.time_period_field(:release_date, select_options, **options)
    assert_equal original_options, options
  end
end
