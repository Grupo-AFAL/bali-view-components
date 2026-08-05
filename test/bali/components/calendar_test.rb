# frozen_string_literal: true

require "test_helper"

class BaliCalendarComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  private

  def component
    Bali::Calendar::Component.new(**@options)
  end

  def monday
    Date.current.prev_occurring(:monday)
  end

  def friday
    Date.current.prev_occurring(:friday)
  end

  public

  def test_renders_calendar_component_with_the_full_week
    @options.merge!(start_date: "2020-01-01", weekdays_only: false)
    render_inline(component) do |c|
      c.with_header(period: c.period, start_date: "2020-01-01")
    end

    assert_selector(".calendar-component")

    assert_selector(".month-view")
    assert_selector("tr > th.text-center", text: "Monday")
    assert_selector("tr > th.text-center", text: "Friday")
    assert_selector("tr > th.text-center", text: "Saturday")
    assert_selector("tr > th.text-center", text: "Sunday")
    assert_selector(".header h3.text-2xl", text: "January 2020")
  end

  def test_renders_calendar_component_from_monday_to_friday
    @options.merge!(start_date: "2020-01-01", weekdays_only: true)
    render_inline(component)

    assert_selector(".calendar-component")

    assert_selector("tr > th.text-center", text: "Monday")
    assert_selector("tr > th.text-center", text: "Tuesday")
    assert_selector("tr > th.text-center", text: "Wednesday")
    assert_selector("tr > th.text-center", text: "Thursday")
    assert_selector("tr > th.text-center", text: "Friday")
    assert_no_selector("tr > th.text-center", text: "Saturday")
    assert_no_selector("tr > th.text-center", text: "Sunday")
  end

  def test_renders_the_calendar_component_hiding_the_calendar_view_options
    @options.merge!(start_date: "2020-01-01", period_switch: false)
    render_inline(component) do |c|
      c.with_header(period: c.period, start_date: "2020-01-01", period_switch: false)
    end

    assert_selector(".calendar-component")

    assert_selector(".header h3.text-2xl", text: "January 2020")
    assert_no_selector(".header a.btn", text: "Week")
    assert_no_selector(".header a.btn", text: "Month")
  end

  def test_renders_the_calendar_component_with_week_view
    @options.merge!(start_date: "2020-01-01", period: :week)
    render_inline(component)

    assert_selector(".calendar-component")

    assert_selector(".week-view")
    assert_selector("tr > th.text-center", text: "Monday")
    assert_selector("tr > th.text-center", text: "Tuesday")
    assert_selector("tr > th.text-center", text: "Wednesday")
    assert_selector("tr > th.text-center", text: "Thursday")
    assert_selector("tr > th.text-center", text: "Friday")
    assert_selector("tr > th.text-center", text: "Saturday")
    assert_selector("tr > th.text-center", text: "Sunday")
  end
  # #prev_day

  def test_prev_day_with_weekends_returns_the_previous_day
    @options.merge!(start_date: monday.to_s, weekdays_only: false)
    assert_equal({ start_time: monday - 1.day }, component.prev_day)
  end

  def test_prev_day_weekdays_only_returns_the_previous_friday
    @options.merge!(start_date: monday.to_s, weekdays_only: true)
    assert_equal({ start_time: monday - 3.days }, component.prev_day)
  end

  def test_prev_day_not_monday_returns_the_previous_day
    @options.merge!(start_date: friday.to_s)
    assert_equal({ start_time: friday - 1.day }, component.prev_day)
  end
  # #next_day

  def test_next_day_with_weekends_returns_the_next_day
    @options.merge!(start_date: friday.to_s, weekdays_only: false)
    assert_equal({ start_time: friday + 1.day }, component.next_day)
  end

  def test_next_day_weekdays_only_returns_the_next_monday
    @options.merge!(start_date: friday.to_s, weekdays_only: true)
    assert_equal({ start_time: friday + 3.days }, component.next_day)
  end

  def test_next_day_not_friday_returns_the_next_day
    @options.merge!(start_date: monday.to_s)
    assert_equal({ start_time: monday + 1.day }, component.next_day)
  end
  # #prev_start_date

  def test_prev_start_date_month_returns_first_date_of_last_month
    prev_date = Date.current
    render_inline(component) do |c|
      prev_date = c.with_header(start_date: "2020-03-03").prev_start_date
    end
    assert_equal(Date.parse("2020-02-01"), prev_date)
  end

  def test_prev_start_date_week_returns_first_date_of_previous_week
    prev_date = Date.current
    render_inline(component) do |c|
      prev_date = c.with_header(start_date: "2020-03-03", period: :week).prev_start_date
    end
    assert_equal(Date.parse("2020-02-24"), prev_date)
  end
  # #next_start_date

  def test_next_start_date_month_returns_first_date_of_next_month
    next_date = Date.current
    render_inline(component) do |c|
      next_date = c.with_header(start_date: "2020-03-03").next_start_date
    end
    assert_equal(Date.parse("2020-04-01"), next_date)
  end

  def test_next_start_date_week_returns_first_date_of_next_week
    next_date = Date.current
    render_inline(component) do |c|
      next_date = c.with_header(start_date: "2020-03-03", period: :week).next_start_date
    end
    assert_equal(Date.parse("2020-03-09"), next_date)
  end
  # #extra_params

  def test_extra_params_returns_params_for_going_back
    params = {}
    render_inline(component) do |c|
      params = c.with_header(start_date: "2020-02-02").extra_params(:prev)
    end
    assert_equal({ start_time: Date.parse("2020-01-01"), period: :month }, params)
  end

  def test_extra_params_returns_params_for_going_forward
    params = {}
    render_inline(component) do |c|
      params = c.with_header(start_date: "2020-02-02").extra_params(:next)
    end
    assert_equal({ start_time: Date.parse("2020-03-01"), period: :month }, params)
  end

  def test_extra_params_returns_params_for_month_view
    params = {}
    render_inline(component) do |c|
      params = c.with_header(start_date: "2020-02-02").extra_params(:month)
    end
    assert_equal({ start_time: Date.parse("2020-02-02"), period: "month" }, params)
  end

  def test_extra_params_returns_params_for_week_view
    params = {}
    render_inline(component) do |c|
      params = c.with_header(start_date: "2020-02-02").extra_params(:week)
    end
    assert_equal({ start_time: Date.parse("2020-02-02"), period: "week" }, params)
  end
  # #sorted_events

  def test_sorted_events_returns_events_sorted_and_grouped_by_start_time
    key1 = Struct.new(:start_time)
    key2 = Struct.new(:start_time)
    value1 = key1.new(Date.parse("2020-02-02"))
    value2 = key2.new(Date.parse("2020-02-01"))

    events = [ value1, value2 ]
    @options.merge!(events: events)

    assert_equal([ Date.parse("2020-02-01"), Date.parse("2020-02-02") ], component.sorted_events.keys)
  end
  # start_date parameter

  def test_start_date_accepts_a_date_object_directly
    date = Date.parse("2020-05-15")
    @options.merge!(start_date: date)
    assert_equal(date, component.start_date)
  end

  def test_start_date_accepts_a_string_and_parses_it
    @options.merge!(start_date: "2020-05-15")
    assert_equal(Date.parse("2020-05-15"), component.start_date)
  end

  def test_start_date_defaults_to_current_date_when_nil
    assert_equal(Date.current, component.start_date)
  end

  def test_start_date_defaults_to_current_date_when_blank
    @options.merge!(start_date: "")
    assert_equal(Date.current, component.start_date)
  end
  # start_date is reachable from the query string, so none of these may raise

  def test_start_date_falls_back_to_today_when_unparseable
    @options.merge!(start_date: "zzz")
    assert_equal(Date.current, component.start_date)
  end

  def test_start_date_falls_back_to_today_when_the_date_does_not_exist
    @options.merge!(start_date: "2026-13-45")
    assert_equal(Date.current, component.start_date)
  end

  def test_start_date_falls_back_to_today_when_given_an_array
    @options.merge!(start_date: [ "1" ])
    assert_equal(Date.current, component.start_date)
  end

  def test_start_date_falls_back_to_today_when_given_a_hash
    @options.merge!(start_date: { "year" => "1" })
    assert_equal(Date.current, component.start_date)
  end

  def test_renders_with_an_unparseable_start_date_instead_of_raising
    @options.merge!(start_date: "zzz")
    render_inline(component)

    assert_selector(".calendar-component")
  end

  # The header parsed its own start_date, and it took the raw value without #to_s,
  # so an Array reached Date.parse as a TypeError rather than an ArgumentError.
  def test_header_falls_back_to_today_when_given_an_array
    header = Bali::Calendar::Header::Component.new(start_date: [ "1" ])
    assert_equal(Date.current, header.start_date)
  end

  def test_header_falls_back_to_today_when_unparseable
    header = Bali::Calendar::Header::Component.new(start_date: "zzz")
    assert_equal(Date.current, header.start_date)
  end

  # period comes off the same query string, and #to_sym is not total either
  def test_period_falls_back_to_month_when_unknown
    @options.merge!(period: "zzz")
    assert_equal(:month, component.period)
  end

  def test_period_falls_back_to_month_when_given_an_array
    @options.merge!(period: [ "1" ])
    assert_equal(:month, component.period)
  end

  def test_period_accepts_the_string_a_query_string_produces
    @options.merge!(period: "week")
    assert_equal(:week, component.period)
  end

  def test_header_period_falls_back_to_month_when_given_an_array
    header = Bali::Calendar::Header::Component.new(start_date: "2020-01-01", period: [ "1" ])
    assert_equal(:month, header.period)
  end
  # weekdays_only parameter

  def test_weekdays_only_true_hides_weekends
    @options.merge!(start_date: "2020-01-01", weekdays_only: true)
    render_inline(component)

    assert_selector("tr > th.text-center", text: "Monday")

    assert_selector("tr > th.text-center", text: "Friday")
    assert_no_selector("tr > th.text-center", text: "Saturday")
    assert_no_selector("tr > th.text-center", text: "Sunday")
  end

  def test_all_week_is_no_longer_read_and_does_not_hide_the_weekend
    @options.merge!(start_date: "2020-01-01", all_week: false)
    render_inline(component)

    assert_selector("tr > th.text-center", text: "Saturday")
    assert_selector("tr > th.text-center", text: "Sunday")
  end

  def test_all_week_reader_is_gone
    refute_respond_to(component, :all_week)
  end
  # helper methods

  def test_month_view_returns_true_for_month_period
    @options.merge!(period: :month)
    assert(component.month_view?)
    refute(component.week_view?)
  end

  def test_week_view_returns_true_for_week_period
    @options.merge!(period: :week)
    refute(component.month_view?)
    assert(component.week_view?)
  end

  def test_show_weekends_returns_inverse_of_weekdays_only
    @options.merge!(weekdays_only: true)
    refute(component.show_weekends?)
    assert(component.weekdays_only?)
  end

  def test_weekdays_only_defaults_to_false_rather_than_nil
    assert_equal(false, component.weekdays_only?)
    assert_equal(true, component.show_weekends?)
  end
  # markup

  def test_frames_the_grid_with_the_card_component
    @options.merge!(start_date: "2020-01-01")
    render_inline(component)

    assert_selector(".calendar-component > .card.month-view > .card-body > .overflow-x-auto")
  end

  def test_week_view_marks_the_card_instead_of_the_month
    @options.merge!(start_date: "2020-01-01", period: :week)
    render_inline(component)

    assert_selector(".calendar-component > .card.week-view")
    assert_no_selector(".month-view")
  end

  def test_weekly_title_class_is_an_explicit_parameter
    @options.merge!(start_date: "2020-01-01", period: :week, weekly_title_class: "text-error")
    render_inline(component)

    assert_selector("td.day > div.text-error")
  end
end

class BaliCalendarEventGrouperTest < ActiveSupport::TestCase
  def setup
    # Ensure the Component file is loaded so EventGrouper (defined in same file) is available
    Bali::Calendar::Component
  end

  def event_class
    Struct.new(:start_time, :end_time)
  end

  def test_groups_single_day_events_by_date
    events = [
      event_class.new(Date.parse("2020-02-01"), nil),
      event_class.new(Date.parse("2020-02-01"), nil)
    ]

    grouper = Bali::Calendar::EventGrouper.new(events)
    assert_equal(2, grouper.by_date[Date.parse("2020-02-01")].size)
  end

  def test_spreads_multi_day_events_across_all_dates
    events = [
      event_class.new(Date.parse("2020-02-01"), Date.parse("2020-02-03"))
    ]

    grouper = Bali::Calendar::EventGrouper.new(events)
    expected = [ Date.parse("2020-02-01"), Date.parse("2020-02-02"), Date.parse("2020-02-03") ]
    assert_equal(expected.sort, grouper.by_date.keys.sort)
  end

  def test_filters_out_events_with_nil_start_time
    events = [
      event_class.new(nil, nil),
      event_class.new(Date.parse("2020-02-01"), nil)
    ]

    grouper = Bali::Calendar::EventGrouper.new(events)
    assert_equal(1, grouper.by_date.values.flatten.size)
  end

  def test_handles_custom_attribute_methods
    custom_class = Struct.new(:begins_at, :ends_at)
    events = [ custom_class.new(Date.parse("2020-02-01"), nil) ]

    grouper = Bali::Calendar::EventGrouper.new(events, start_method: :begins_at, end_method: :ends_at)
    assert_equal(1, grouper.by_date[Date.parse("2020-02-01")].size)
  end
end
