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
  # year view
  #
  # normalize_period degrades anything it does not recognise to :month WITHOUT
  # raising, so a year view that was never wired up would still answer 200 and
  # paint a month. Every assertion below has to name something only twelve
  # months can produce; "it rendered" proves nothing here.

  def test_year_is_a_period_rather_than_falling_back_to_month
    @options.merge!(period: "year")
    assert_equal(:year, component.period)
    assert(component.year_view?)
    refute(component.month_view?)
  end

  def test_year_view_renders_twelve_months
    @options.merge!(start_date: "2020-06-15", period: :year)
    render_inline(component)

    assert_selector(".year-view")
    assert_selector(".year-month", count: 12)
    assert_no_selector("table")
  end

  def test_year_view_names_every_month
    @options.merge!(start_date: "2020-06-15", period: :year)
    render_inline(component)

    %w[January February March April May June
       July August September October November December].each do |month|
      assert_selector(".year-month h4", text: month)
    end
  end

  def test_year_view_draws_every_day_of_the_year
    @options.merge!(start_date: "2020-06-15", period: :year)
    render_inline(component)

    assert_selector(".year-day", count: 366)
  end

  def test_year_view_keeps_seven_columns_when_weekdays_only_is_set
    @options.merge!(start_date: "2020-06-15", period: :year, weekdays_only: true)
    render_inline(component)

    assert_selector(".year-weekday", count: 84) # 12 months x 7 columns
    assert_selector(".year-day", count: 366)
  end

  def test_year_view_labels_the_weekdays_from_the_first_day_of_the_week
    @options.merge!(start_date: "2020-06-15", period: :year)
    render_inline(component)

    initials = page.all(".year-weekday").first(7).map(&:text)
    assert_equal(%w[Mon Tue Wed Thu Fri Sat Sun], initials)
  end

  def test_year_view_dims_days_without_events
    @options.merge!(start_date: "2020-06-15", period: :year)
    render_inline(component)

    assert_selector(".year-day.text-base-content\\/40", count: 366)
  end

  def test_year_view_highlights_days_with_events
    @options.merge!(start_date: "2020-01-01", period: :year, events: [ year_event("2020-03-05") ])
    render_inline(component)

    assert_selector(".year-day.bg-base-content\\/20", count: 1)
  end

  def test_year_view_paints_the_day_with_the_variant_the_host_returns
    @options.merge!(
      start_date: "2020-01-01", period: :year, events: [ year_event("2020-03-05") ],
      day_variant: ->(_day, _events) { :success }
    )
    render_inline(component)

    assert_selector(".year-day.bg-success", count: 1)
  end

  def test_year_view_rejects_a_variant_that_is_not_a_bali_colour
    @options.merge!(
      start_date: "2020-01-01", period: :year, events: [ year_event("2020-03-05") ],
      day_variant: ->(_day, _events) { :chartreuse }
    )

    error = assert_raises(ArgumentError) { render_inline(component) }
    assert_match(/day_variant/, error.message)
  end

  # One colour per day and a dot for the rest: the host owns the precedence
  # between its own states, the component only knows how many there are.
  def test_year_view_marks_a_day_holding_more_than_one_event
    @options.merge!(
      start_date: "2020-01-01", period: :year,
      events: [ year_event("2020-03-05"), year_event("2020-03-05"), year_event("2020-04-02") ]
    )
    render_inline(component)

    assert_selector(".year-day.has-multiple", count: 1)
  end

  def test_year_view_does_not_link_a_day_without_a_day_url
    @options.merge!(start_date: "2020-01-01", period: :year, events: [ year_event("2020-03-05") ])
    render_inline(component)

    assert_no_selector(".year-month a")
    assert_selector("time.year-day", count: 366)
  end

  def test_year_view_links_the_days_the_day_url_names
    @options.merge!(
      start_date: "2020-01-01", period: :year, events: [ year_event("2020-03-05") ],
      day_url: ->(day, events) { "/days/#{day}" if events.any? }
    )
    render_inline(component)

    assert_selector("a.year-day[href='/days/2020-03-05']", count: 1)
    assert_selector("a.year-day", count: 1)
    assert_selector("a.year-day[aria-label='5 March 2020']", count: 1)
  end

  # A bare <span> maps to `generic`, which ARIA does not name, so the full date on an
  # unlinked cell rides on <time datetime> instead of an aria-label that does nothing.
  def test_year_view_carries_the_machine_readable_date_on_every_unlinked_day
    @options.merge!(start_date: "2020-01-01", period: :year)
    render_inline(component)

    assert_selector("time.year-day[datetime='2020-03-05']", count: 1)
    assert_selector("time.year-day", count: 366)
  end

  def test_month_summary_receives_the_month_and_its_own_events
    seen = []
    @options.merge!(
      start_date: "2020-01-01", period: :year,
      events: [ year_event("2020-03-05"), year_event("2020-03-19") ],
      month_summary: lambda { |month, events|
        seen << [ month, events.size ]
        "#{events.size} on"
      }
    )
    render_inline(component)

    assert_selector(".year-month", text: "2 on", count: 1)
    assert_equal(12, seen.size)
    assert_equal([ Date.parse("2020-03-01"), 2 ], seen[2])
  end

  def test_month_summary_is_omitted_when_the_host_returns_nothing
    @options.merge!(
      start_date: "2020-01-01", period: :year, month_summary: ->(_month, _events) { nil }
    )
    render_inline(component)

    assert_no_selector(".year-month .badge")
  end

  # Tippy is mounted per hover card, so a year of empty cells would cost 365
  # instances to show 365 empty popups.
  def test_year_view_mounts_a_hover_card_only_on_days_with_events
    @options.merge!(
      start_date: "2020-01-01", period: :year,
      events: [ year_event("2020-03-05"), year_event("2020-08-11") ],
      template: "calendar_fixtures/day"
    )
    render_inline(component)

    assert_selector(".year-month .hover-card-component", count: 2)
  end

  def test_year_view_renders_no_hover_card_without_a_template
    @options.merge!(
      start_date: "2020-01-01", period: :year, events: [ year_event("2020-03-05") ]
    )
    render_inline(component)

    assert_no_selector(".hover-card-component")
  end

  def test_year_view_renders_with_all_three_lambdas_nil
    @options.merge!(start_date: "2020-01-01", period: :year)
    render_inline(component)

    assert_selector(".year-month", count: 12)
  end

  # month_size — the level names the MONTH, not the view

  def test_month_size_defaults_to_md
    @options.merge!(start_date: "2020-01-01", period: :year)
    render_inline(component)

    assert_includes(year_grid_classes,
                    Bali::Calendar::YearGrid::Component::MONTH_SIZES.fetch(:md))
  end

  def test_every_month_size_emits_its_own_track_minimum
    Bali::Calendar::YearGrid::Component::MONTH_SIZES.each do |size, css|
      @options.merge!(start_date: "2020-01-01", period: :year, month_size: size)
      render_inline(component)

      assert_includes(year_grid_classes, css, "month_size: #{size.inspect}")
    end
  end

  def test_month_size_accepts_the_string_form_too
    @options.merge!(start_date: "2020-01-01", period: :year, month_size: "lg")
    render_inline(component)

    assert_includes(year_grid_classes,
                    Bali::Calendar::YearGrid::Component::MONTH_SIZES.fetch(:lg))
  end

  # Written in code, never read off a query string, so an unknown level is a
  # mistake to report — the opposite call from normalize_period.
  def test_month_size_rejects_a_level_that_is_not_on_the_scale
    @options.merge!(start_date: "2020-01-01", period: :year, month_size: :enormous)

    error = assert_raises(ArgumentError) { render_inline(component) }
    assert_match(/month_size/, error.message)
    assert_match(/:xs, :sm, :md, :lg, :xl/, error.message)
  end

  # The ramp of breakpoints this replaced measured the VIEWPORT, so a calendar in a
  # 400px drawer on a wide screen drew four columns 76px wide with 9px day cells.
  # `auto-fit` measures the container instead. Nobody may put the ramp back.
  def test_year_grid_emits_no_breakpoint_column_classes
    @options.merge!(start_date: "2020-01-01", period: :year)
    render_inline(component)

    refute_match(/(sm|md|lg|xl):grid-cols-/, year_grid_classes)
  end

  # The names come from I18n, never from a literal: `date.month_names` is 1-indexed
  # and `date.abbr_day_names` starts on Sunday, so both are easy to get subtly wrong
  # in a grid that starts on Monday.
  def test_year_view_names_the_months_and_weekdays_in_spanish
    @options.merge!(start_date: "2020-06-15", period: :year)
    I18n.with_locale(:es) { render_inline(component) }

    assert_selector(".year-month h4", text: "Enero")
    assert_selector(".year-month h4", text: "Diciembre")
    assert_equal(%w[Lun Mar Mié Jue Vie Sáb Dom],
                 page.all(".year-weekday").first(7).map(&:text))
  end

  def test_year_view_header_shows_the_year_in_spanish_too
    @options.merge!(start_date: "2020-03-03", period: :year)
    I18n.with_locale(:es) do
      render_inline(component) do |c|
        c.with_header(start_date: "2020-03-03", period: :year, route_path: "/c",
                      period_switch: %i[month year])
      end
    end

    assert_selector(".header h3.text-2xl", text: "2020")
    assert_selector(".header a.btn", text: "Año")
    assert_selector(".header a.btn", text: "Mes")
  end

  # The one +mobile template in the package answers "phone" with the day view for
  # every other period; the year grid reflows instead of being replaced.
  def test_year_view_is_drawn_on_mobile_too
    @options.merge!(start_date: "2020-01-01", period: :year)
    with_variant(:mobile) { render_inline(component) }

    assert_selector(".year-view")
    assert_selector(".year-month", count: 12)
    assert_no_selector(".day-view")
  end

  def test_year_view_marks_the_card_with_year_view
    @options.merge!(start_date: "2020-01-01", period: :year)
    render_inline(component)

    assert_selector(".calendar-component > .card.year-view")
    assert_no_selector(".month-view")
    assert_no_selector(".week-view")
  end
  # header — year navigation

  def test_prev_start_date_year_returns_first_date_of_last_year
    prev_date = Date.current
    render_inline(component) do |c|
      prev_date = c.with_header(start_date: "2020-03-03", period: :year).prev_start_date
    end
    assert_equal(Date.parse("2019-01-01"), prev_date)
  end

  def test_next_start_date_year_returns_first_date_of_next_year
    next_date = Date.current
    render_inline(component) do |c|
      next_date = c.with_header(start_date: "2020-03-03", period: :year).next_start_date
    end
    assert_equal(Date.parse("2021-01-01"), next_date)
  end

  def test_extra_params_returns_params_for_year_view
    params = {}
    render_inline(component) do |c|
      params = c.with_header(start_date: "2020-02-02").extra_params(:year)
    end
    assert_equal({ start_time: Date.parse("2020-02-02"), period: "year" }, params)
  end

  # The round trip #route builds, which is what a host actually clicks.
  def test_route_for_the_year_button_carries_the_period_and_the_date
    href = ""
    render_inline(component) do |c|
      header = c.with_header(start_date: "2020-02-02", route_path: "/calendar?q=x")
      href = header.route(header.extra_params(:year))
    end

    assert_equal("/calendar?period=year&q=x&start_time=2020-02-02", href)
  end

  def test_header_shows_only_the_year_in_the_year_view
    @options.merge!(start_date: "2020-03-03", period: :year)
    render_inline(component) do |c|
      c.with_header(start_date: "2020-03-03", period: :year)
    end

    assert_selector(".header h3.text-2xl", text: "2020")
    assert_no_selector(".header h3.text-2xl", text: "March")
  end
  # header — period_switch takes an array as well as a boolean

  def test_period_switch_true_still_renders_exactly_week_and_month
    render_inline(component) do |c|
      c.with_header(start_date: "2020-01-01", route_path: "/calendar", period_switch: true)
    end

    assert_selector(".header a.btn", text: "Week")
    assert_selector(".header a.btn", text: "Month")
    assert_no_selector(".header a.btn", text: "Year")
    assert_no_selector(".header a.btn", text: "Day")
  end

  def test_period_switch_false_renders_no_switch_at_all
    render_inline(component) do |c|
      c.with_header(start_date: "2020-01-01", route_path: "/calendar", period_switch: false)
    end

    assert_no_selector(".header a.btn", text: "Week")
    assert_no_selector(".header a.btn", text: "Month")
    assert_no_selector(".header a.btn", text: "Year")
  end

  def test_period_switch_accepts_an_array_of_periods
    render_inline(component) do |c|
      c.with_header(start_date: "2020-01-01", route_path: "/calendar",
                    period: :year, period_switch: %i[month year])
    end

    assert_selector(".header a.btn", text: "Month")
    assert_selector(".header a.btn", text: "Year")
    assert_no_selector(".header a.btn", text: "Week")
  end

  def test_period_switch_outlines_every_period_but_the_current_one
    render_inline(component) do |c|
      c.with_header(start_date: "2020-01-01", route_path: "/calendar",
                    period: :year, period_switch: %i[month year])
    end

    assert_selector(".header a.btn-outline", text: "Month")
    assert_no_selector(".header a.btn-outline", text: "Year")
  end

  def test_period_switch_drops_a_value_that_is_not_a_period
    header = Bali::Calendar::Header::Component.new(
      start_date: "2020-01-01", route_path: "/calendar", period_switch: %i[month decade]
    )

    assert_equal([ :month ], header.switch_periods)
  end

  private

  def year_grid_classes
    page.find(".year-grid")[:class]
  end

  def year_event(date)
    Struct.new(:start_time).new(Date.parse(date))
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
