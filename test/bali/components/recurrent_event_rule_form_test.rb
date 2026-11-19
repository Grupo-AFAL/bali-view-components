# frozen_string_literal: true

require "test_helper"

class BaliRecurrentEventRuleFormComponentTest < ComponentTestCase
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

  # Ids are namespaced by the form's own `field_id`, so they are unique on a page
  # without being random: the previous `SecureRandom.hex(4)` prefix changed on
  # every render, which no `<label for>` and no Turbo morph can follow.
  def test_basic_rendering_namespaces_control_ids_with_the_form_field_id
    render_inline(component)
    radio = page.find('input[type="radio"]', match: :first)
    assert_equal("movie_rule_yearly_on_1", radio["id"])
  end

  def test_basic_rendering_gives_every_unlabelled_control_its_own_id_and_name
    render_inline(component)
    ids = page.all("select, input[type='number'], input[type='text']", visible: :all).map { |n| n["id"] }

    assert_equal(ids.uniq, ids, "duplicate ids inside a single recurrence form: #{ids.inspect}")
    assert(ids.all? { |id| id.to_s.start_with?("movie_rule_") }, ids.inspect)
    assert(page.all("select", visible: :all).all? { |n| n["aria-label"].present? },
           "a select with no accessible name")
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

  # #1051. With nothing selected the browser keeps the first option — disabled
  # whenever the host excluded it — and the controller, which builds its default
  # rule from this selection, then persisted a frequency the host had forbidden.
  # Weekly and not daily: the select lists them in catalogue order, so the first
  # allowed one on screen is the one to open on.
  def test_frequency_options_filtering_preselects_the_first_allowed_frequency
    render_inline(component(frequency_options: %w[daily weekly]))
    selected = page.find('select[name="freq"] option[selected]')
    assert_equal("2", selected["value"])
    refute(selected["disabled"])
  end

  def test_frequency_options_filtering_falls_back_to_yearly_when_none_is_allowed
    render_inline(component(frequency_options: []))
    assert_equal("0", page.find('select[name="freq"] option[selected]')["value"])
  end
  # frequency select

  def test_frequency_select_renders_all_frequency_options_by_default
    render_inline(component)
    freq_select = page.find('select[name="freq"]')
    assert_equal(5, freq_select.all("option").count)
  end

  def test_frequency_select_opens_on_yearly_when_every_frequency_is_allowed
    render_inline(component)
    assert_equal("0", page.find('select[name="freq"] option[selected]')["value"])
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

  def test_weekday_labels_are_unique_in_every_locale
    %i[en es].each do |locale|
      I18n.with_locale(locale) do
        render_inline(component)
        labels = weekday_circles.map { |_, text, _| text }

        assert_equal(7, labels.size)
        assert_equal(labels.uniq, labels, "ambiguous weekday labels for #{locale}: #{labels.inspect}")
      end
    end
  end

  def test_weekday_labels_in_spanish_follow_the_calendar_convention
    I18n.with_locale(:es) do
      render_inline(component)
      assert_equal(%w[D L M X J V S], weekday_circles.map { |_, text, _| text })
    end
  end

  def test_weekday_labels_in_english_are_two_letters
    I18n.with_locale(:en) do
      render_inline(component)
      assert_equal(%w[Su Mo Tu We Th Fr Sa], weekday_circles.map { |_, text, _| text })
    end
  end

  def test_weekday_controls_are_named_with_the_full_day_name
    I18n.with_locale(:es) do
      render_inline(component)
      names = weekday_circles.map(&:first)

      assert_equal(I18n.t("date.day_names"), names)
      assert_empty(page.all('input[data-rrule-attr="byweekday"][aria-label]', visible: :all))
    end
  end

  def test_weekday_circles_fall_back_to_abbr_day_names_when_the_locale_has_no_initials
    abbr = %w[Dim Lun Mar Mer Jeu Ven Sam]
    available = I18n.available_locales
    default = I18n.default_locale
    I18n.available_locales = available + [ :fr ]
    # Drop the default-locale hop so fr does not borrow the English initials.
    I18n.fallbacks.defaults = [ :fr ]
    I18n.fallbacks.clear
    I18n.backend.store_translations(:fr, date: { month_names: [ nil ] + (1..12).map { |n| "mois #{n}" }, abbr_day_names: abbr, day_names: %w[dimanche lundi mardi mercredi jeudi vendredi samedi] })
    I18n.with_locale(:fr) do
      render_inline(component)
      assert_equal(abbr, weekday_circles.map { |_, text, _| text })
    end
  ensure
    I18n.fallbacks.defaults = [ default ]
    I18n.available_locales = available
    I18n.fallbacks.clear
    I18n.backend.reload!
  end

  def test_weekday_order_and_rrule_values_are_unchanged
    render_inline(component)
    assert_equal(%w[6 0 1 2 3 4 5], weekday_circles.map(&:last))
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

  def test_daisyui_classes_applies_input_class_to_number_inputs
    render_inline(component)
    assert_selector('input.input[type="number"]')
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

  private

  # Each weekday circle as [accessible name, visible text, RRULE value] (#1632).
  def weekday_circles
    page.all('input[data-rrule-attr="byweekday"][type="checkbox"]', visible: :all).map do |box|
      label = page.find("label[for='#{box['id']}']", visible: :all)
      [ label.find("span.sr-only", visible: :all).text, label.find("span[aria-hidden]", visible: :all).text, box["value"] ]
    end
  end
end
