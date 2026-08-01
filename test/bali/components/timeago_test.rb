# frozen_string_literal: true

require "test_helper"

class BaliTimeagoComponentTest < ComponentTestCase
  def setup
    @datetime = 10.seconds.ago
    @options = {}
    @component = Bali::Timeago::Component.new(@datetime, **@options)
  end

  def test_basic_rendering_renders_a_time_element
    render_inline(@component)
    assert_selector("time.timeago-component")
  end

  def test_basic_rendering_includes_the_stimulus_controller
    render_inline(@component)
    assert_selector('[data-controller="timeago"]')
  end

  def test_basic_rendering_includes_the_datetime_value_for_stimulus
    render_inline(@component)
    assert_selector("[data-timeago-datetime-value]")
  end

  def test_basic_rendering_includes_the_standard_datetime_html_attribute
    render_inline(@component)
    assert_selector("time[datetime]")
  end

  def test_basic_rendering_sets_the_locale_value_from_i18n
    render_inline(@component)
    assert_selector('[data-timeago-locale-value="en"]')
  end

  def test_default_values_defaults_include_seconds_to_true
    render_inline(@component)
    assert_selector('[data-timeago-include-seconds-value="true"]')
  end

  def test_default_values_defaults_add_suffix_to_false
    render_inline(@component)
    assert_selector('[data-timeago-add-suffix-value="false"]')
  end

  def test_default_values_does_not_include_refresh_interval_when_not_set
    render_inline(@component)
    assert_no_selector("[data-timeago-refresh-interval-value]")
  end

  def test_with_refresh_interval_includes_the_refresh_interval_value
    render_inline(Bali::Timeago::Component.new(@datetime, refresh_interval: 5000))
    assert_selector('[data-timeago-refresh-interval-value="5000"]')
  end

  def test_with_include_seconds_false_sets_include_seconds_to_false
    render_inline(Bali::Timeago::Component.new(@datetime, include_seconds: false))
    assert_selector('[data-timeago-include-seconds-value="false"]')
  end

  def test_with_add_suffix_true_sets_add_suffix_to_true
    render_inline(Bali::Timeago::Component.new(@datetime, add_suffix: true))
    assert_selector('[data-timeago-add-suffix-value="true"]')
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Timeago::Component.new(@datetime, class: "custom-class"))
    assert_selector("time.timeago-component.custom-class")
  end

  def test_options_passthrough_accepts_custom_data_attributes
    render_inline(Bali::Timeago::Component.new(@datetime, data: { testid: "timeago-test" }))
    assert_selector('[data-testid="timeago-test"]')
  end

  def test_options_passthrough_preserves_custom_data_attributes_alongside_controller_data
    render_inline(Bali::Timeago::Component.new(@datetime, data: { custom: "value" }))
    assert_selector('[data-custom="value"]')
    assert_selector('[data-controller="timeago"]')
  end

  def test_options_passthrough_accepts_arbitrary_html_attributes
    render_inline(Bali::Timeago::Component.new(@datetime, id: "my-timeago", title: "Last updated"))
    assert_selector('time#my-timeago[title="Last updated"]')
  end

  def test_with_different_datetime_types_handles_time_objects
    render_inline(Bali::Timeago::Component.new(Time.current))
    assert_selector("time[datetime]")
  end

  def test_with_different_datetime_types_handles_datetime_objects
    render_inline(Bali::Timeago::Component.new(DateTime.current))
    assert_selector("time[datetime]")
  end

  def test_with_different_datetime_types_handles_activesupport_timewithzone
    render_inline(Bali::Timeago::Component.new(Time.current.in_time_zone("UTC")))
    assert_selector("time[datetime]")
  end

  def test_i18n_support_uses_spanish_locale_when_set
    I18n.with_locale(:es) do
      render_inline(@component)
      assert_selector('[data-timeago-locale-value="es"]')
    end
  end

  def test_server_rendering_renders_the_relative_time_so_the_element_is_never_empty
    render_inline(Bali::Timeago::Component.new(5.minutes.ago))
    assert_selector("time.timeago-component", text: "5 minutes")
  end

  def test_server_rendering_adds_the_suffix_when_requested
    render_inline(Bali::Timeago::Component.new(5.minutes.ago, add_suffix: true))
    assert_selector("time.timeago-component", text: "5 minutes ago")
  end

  # Only the suffix is Bali's to translate. The distance itself comes from Rails'
  # own `datetime.distance_in_words`, which this gem does not ship and must not
  # squat on — a host wanting a localized first paint installs `rails-i18n`.
  def test_server_rendering_translates_the_suffix_it_owns
    I18n.with_locale(:es) do
      render_inline(Bali::Timeago::Component.new(5.minutes.ago, add_suffix: true))
      assert_selector("time.timeago-component", text: /\Ahace 5 /)
    end
  end

  def test_nil_datetime_renders_a_placeholder_instead_of_raising
    render_inline(Bali::Timeago::Component.new(nil))
    assert_selector("span.timeago-component", text: "—")
  end

  def test_nil_datetime_renders_no_time_element_because_there_is_no_datetime_to_carry
    render_inline(Bali::Timeago::Component.new(nil))
    assert_no_selector("time")
  end

  def test_nil_datetime_does_not_attach_the_controller
    render_inline(Bali::Timeago::Component.new(nil))
    assert_no_selector('[data-controller="timeago"]')
  end

  def test_nil_datetime_keeps_custom_html_attributes
    render_inline(Bali::Timeago::Component.new(nil, id: "never", class: "custom-class"))
    assert_selector("span#never.timeago-component.custom-class")
  end

  def test_constants_has_base_classes_constant
    assert_equal("timeago-component", Bali::Timeago::Component::BASE_CLASSES)
  end

  def test_constants_has_controller_constant
    assert_equal("timeago", Bali::Timeago::Component::CONTROLLER)
  end
end
