# frozen_string_literal: true

require "test_helper"

class Bali_RecurrentEventRuleForm_ComponentTest < ComponentTestCase
  def setup
    @helper = TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
    @resource = Movie.new
    @builder = Bali::FormBuilder.new(:movie, @resource, @helper, {})
  end

  def component(options = {})
    Bali::RecurrentEventRuleForm::Component.new(form: @builder, method: :rule, **options)
  end

  # basic rendering

  def test_basic_rendering_renders_the_component_wrapper
    render_inline(component)
    assert_selector("div.recurrent-event-rule-form-component")
  end
  def test_basic_rendering_applies_the_recurrent_event_rule_stimulus_controller
    render_inline(component)
    assert_selector('[data-controller="recurrent-event-rule"]')
  end
  def test_basic_rendering_renders_hidden_input_for_storing_the_rrule_value
    render_inline(component)
    assert_selector('input[type="hidden"][data-recurrent-event-rule-target="input"]', visible: :hidden)
  end
  def test_basic_rendering_generates_unique_ids_for_inputs
    render_inline(component)
    radio = page.find('input[type="radio"]', match: :first)
    assert_match(/[a-f0-9]{8}_yearly/, radio["id"])
  end
  # with value

  def test_with_value_renders_the_hidden_input_with_the_provided_value
    render_inline(component(value: "FREQ=MONTHLY;INTERVAL=2"))
    assert_selector('input[type="hidden"][value="FREQ=MONTHLY;INTERVAL=2"]', visible: :hidden)
  end
  # disabled state

  def test_disabled_state_disables_the_frequency_select
    render_inline(component(disabled: true))
    assert_selector('select[name="freq"][disabled]')
  end
  def test_disabled_state_disables_the_hidden_input
    render_inline(component(disabled: true))
    assert_selector('input[type="hidden"][disabled]', visible: :hidden)
  end
  def test_disabled_state_disables_the_interval_input
    render_inline(component(disabled: true))
    assert_selector('input[type="number"][name="interval"][disabled]')
  end
  def test_disabled_state_disables_the_end_method_select
    render_inline(component(disabled: true))
    assert_selector('select[name="end"][disabled]')
  end
  # skip_end_method option

  def test_skip_end_method_option_hides_the_end_method_section
    render_inline(component(skip_end_method: true))
    assert_selector("fieldset.hidden", text: /End|Termina/)
  end
  # frequency_options filtering

  def test_frequency_options_filtering_disables_frequencies_not_in_the_allowed_list
    render_inline(component(frequency_options: %w[daily weekly]))
    freq_select = page.find('select[name="freq"]')
    yearly_option = freq_select.find('option[value="0"]')
    monthly_option = freq_select.find('option[value="1"]')
    assert(yearly_option["disabled"])
    assert(monthly_option["disabled"])
  end
  def test_frequency_options_filtering_enables_frequencies_in_the_allowed_list
    render_inline(component(frequency_options: %w[daily weekly]))
    freq_select = page.find('select[name="freq"]')
    weekly_option = freq_select.find('option[value="2"]')
    daily_option = freq_select.find('option[value="3"]')
    refute(weekly_option["disabled"])
    refute(daily_option["disabled"])
  end
  # frequency select

  def test_frequency_select_renders_all_frequency_options_by_default
    render_inline(component)
    freq_select = page.find('select[name="freq"]')
    assert_equal(5, freq_select.all("option").count)
  end
  def test_frequency_select_has_correct_values_for_frequencies
    render_inline(component)
    assert_selector('select[name="freq"] option[value="0"]') # yearly
    assert_selector('select[name="freq"] option[value="1"]') # monthly
    assert_selector('select[name="freq"] option[value="2"]') # weekly
    assert_selector('select[name="freq"] option[value="3"]') # daily
    assert_selector('select[name="freq"] option[value="4"]') # hourly
  end

  # ending options

  def test_ending_options_renders_the_end_method_select
    render_inline(component)
    assert_selector('select[name="end"]')
  end
  def test_ending_options_has_never_after_and_on_date_options
    render_inline(component)
    assert_selector('select[name="end"] option[value=""]')    # never
    assert_selector('select[name="end"] option[value="count"]') # after
    assert_selector('select[name="end"] option[value="until"]') # on_date
  end

  # yearly customization section

  def test_yearly_customization_section_renders_month_selector
    render_inline(component)
    assert_selector('select[name="bymonth"]')
  end
  def test_yearly_customization_section_renders_month_day_selector
    render_inline(component)
    assert_selector('select[name="bymonthday"]')
  end
  def test_yearly_customization_section_renders_bysetpos_selector_for_on_the_option
    render_inline(component)
    assert_selector('select[name="bysetpos"]')
  end
  def test_yearly_customization_section_renders_byweekday_selector_for_on_the_option
    render_inline(component)
    assert_selector('select[name="byweekday"]')
  end
  # weekly customization section

  def test_weekly_customization_section_renders_day_checkboxes
    render_inline(component)
    assert_selector('input[type="checkbox"][data-rrule-attr="byweekday"]', count: 7)
  end
  def test_weekly_customization_section_applies_peer_classes_for_label_styling
    render_inline(component)
    assert_selector('input[type="checkbox"].peer.sr-only')
  end
  # DaisyUI classes

  def test_daisyui_classes_applies_select_bordered_to_selects
    render_inline(component)
    assert_selector('select.select.select-bordered[name="freq"]')
  end
  def test_daisyui_classes_applies_input_bordered_to_number_inputs
    render_inline(component)
    assert_selector('input.input.input-bordered[type="number"]')
  end
  def test_daisyui_classes_applies_radio_class_to_radio_buttons
    render_inline(component)
    assert_selector('input[type="radio"].radio')
  end
  # Stimulus data attributes

  def test_stimulus_data_attributes_has_intervalinputcontainer_target
    render_inline(component)
    assert_selector('[data-recurrent-event-rule-target="intervalInputContainer"]')
  end
  def test_stimulus_data_attributes_has_freqcustomizationinputscontainer_targets
    render_inline(component)
    assert_selector('[data-recurrent-event-rule-target="freqCustomizationInputsContainer"]', minimum: 4)
  end
  def test_stimulus_data_attributes_has_endmethodselect_target
    render_inline(component)
    assert_selector('[data-recurrent-event-rule-target="endMethodSelect"]')
  end
  def test_stimulus_data_attributes_has_endcustomizationinputscontainer_targets
    render_inline(component)
    assert_selector('[data-recurrent-event-rule-target="endCustomizationInputsContainer"]', minimum: 3)
  end
  # options passthrough

  def test_options_passthrough_merges_custom_classes
    render_inline(component(class: "custom-class"))
    assert_selector("div.recurrent-event-rule-form-component.custom-class")
  end
  # i18n

  def test_i18n_translates_frequency_labels
    render_inline(component)
    assert_text(/Yearly|Anualmente/i)
  end
  def test_i18n_translates_repeat_label
    render_inline(component)
    assert_text(/Repeat|Repetir/i)
  end
  def test_i18n_translates_end_label
    render_inline(component)
    assert_text(/End|Termina/i)
  end
end
