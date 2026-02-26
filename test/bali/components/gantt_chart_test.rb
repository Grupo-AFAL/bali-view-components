# frozen_string_literal: true

require "test_helper"

class Bali_GanttChart_ComponentTest < ComponentTestCase
  def setup
    @date = Date.current
    @tasks = [
      { id: 1, name: "Task 1", start_date: @date, end_date: @date + 6.days,
        update_url: "/task/1", href: "/task/1" },
      { id: 2, name: "Task 1.1", start_date: @date + 2.days, end_date: @date + 10.days,
        update_url: "/task/2", parent_id: 1, href: "/task/2", data: { turbo: false, action: "modal#open" } },
      { id: 3, name: "Task 1.2", start_date: @date + 2.days, end_date: @date + 10.days,
        update_url: "/task/3", parent_id: 1 },
      { id: 4, name: "Task 1.2.1", start_date: @date + 6.days, end_date: @date + 12.days,
        update_url: "/task/4", parent_id: 3 },
      { id: 5, name: "Task 3", start_date: @date + 6.days, end_date: @date + 12.days,
        update_url: "/task/5" },
      { id: 6, name: "Task 4", start_date: @date + 10.days, end_date: @date + 16.days,
        update_url: "/task/6", dependent_on_id: 4 },
      { id: 7, name: "Milestone", start_date: @date + 12.days, end_date: @date + 20.days,
        update_url: "/task/7" }
    ]
    @options = { tasks: @tasks }
  end

  def component
    Bali::GanttChart::Component.new(**@options)
  end

  def month_name(number)
    I18n.t("date.month_names")[number]
  end

  # chart actions

  def test_renders_view_mode_buttons
    render_inline(component) do |c|
      c.with_view_mode_button(label: "Day", zoom: :day)
      c.with_view_mode_button(label: "Week", zoom: :week)
      c.with_view_mode_button(label: "Month", zoom: :month)
    end
    assert_selector(".gantt-chart-actions .btn", text: "Day")
    assert_selector(".gantt-chart-actions .btn", text: "Week")
    assert_selector(".gantt-chart-actions .btn", text: "Month")
  end
  # task list

  def test_task_list_renders_the_list_header
    render_inline(component)
    assert_selector(".gantt-chart-header", text: "Name")
  end
  def test_task_list_renders_a_row_for_every_task
    render_inline(component)
    assert_selector(".gantt-chart-row", text: "Task 1")
    assert_selector(".gantt-chart-row", text: "Task 1.1")
    assert_selector(".gantt-chart-row", text: "Task 1.2")
    assert_selector(".gantt-chart-row", text: "Task 1.2.1")
    assert_selector(".gantt-chart-row", text: "Task 3")
    assert_selector(".gantt-chart-row", text: "Task 4")
    assert_selector(".gantt-chart-row", text: "Milestone")
  end
  def test_task_list_renders_an_arrow_icon_for_folding_parent_tasks
    render_inline(component)
    assert_selector('[data-id="1"] .chevron-down')
  end
  def test_task_list_renders_a_link_when_an_href_is_provided_with_default_zoom
    render_inline(component)
    assert_selector('a.task-name[href="/task/2?zoom=day"]', text: "Task 1.1")
  end
  def test_task_list_renders_a_div_when_no_href_is_provided
    render_inline(component)
    assert_selector("div.task-name", text: "Task 1.2")
  end
  def test_task_list_renders_a_tooltip_for_each_task
    render_inline(component)
    assert_selector(".tooltip-component", text: "Task 1")
  end
  def test_task_list_renders_a_list_resizer
    render_inline(component)
    assert_selector(".gantt-chart-list-resizer")
  end
  # task list custom zoom

  def test_task_list_custom_zoom_renders_a_link_with_month_zoom
    @options.merge!(zoom: :month)
    render_inline(component)
    assert_selector('a.task-name[href="/task/2?zoom=month"]', text: "Task 1.1")
  end
  def test_task_list_custom_zoom_renders_a_link_with_week_zoom
    @options.merge!(zoom: :week)
    render_inline(component)
    assert_selector('a.task-name[href="/task/2?zoom=week"]', text: "Task 1.1")
  end
  # timeline

  def test_timeline_renders_a_marker_for_todays_date
    render_inline(component)
    assert_selector(".gantt-chart-today-marker", text: "Today")
  end
  # timeline - day zoom, tasks begin from current month

  def test_timeline_day_zoom_earliest_header_renders_from_3_months_before_first_task
    @options.merge!(zoom: :day)
    render_inline(component)
    @end_date = @date + 20.days
    start_month = month_name((@date - 3.months).beginning_of_month.month)
    assert_selector(".gantt-chart-header-month", text: start_month)
  end
  def test_timeline_day_zoom_earliest_header_does_not_render_before_start_date
    @options.merge!(zoom: :day)
    render_inline(component)
    invalid_start_month = month_name((@date - 4.months).beginning_of_month.month)
    assert_no_selector(".gantt-chart-header-month", text: invalid_start_month)
  end
  def test_timeline_day_zoom_latest_header_renders_3_months_after_last_task
    @options.merge!(zoom: :day)
    render_inline(component)
    @end_date = @date + 20.days
    end_month = month_name((@end_date + 3.months).end_of_month.month)
    assert_selector(".gantt-chart-header-month", text: end_month)
  end
  def test_timeline_day_zoom_latest_header_does_not_render_after_end_date
    @options.merge!(zoom: :day)
    render_inline(component)
    @end_date = @date + 20.days
    invalid_end_month = month_name((@end_date + 4.months).end_of_month.month)
    assert_no_selector(".gantt-chart-header-month", text: invalid_end_month)
  end
  # timeline - day zoom, tasks begin after current month

  def test_timeline_day_zoom_tasks_after_current_month_renders_from_1_month_before_current_date
    base = Date.current.beginning_of_month
    future_tasks = [
      { id: 1, name: "Task 1", start_date: base + 5.months, end_date: base + 5.months + 1.week },
      { id: 2, name: "Task 2", start_date: base + 6.months, end_date: base + 6.months + 1.week }
    ]
    render_inline(Bali::GanttChart::Component.new(tasks: future_tasks))
    start_month = month_name((base - 1.month).month)
    assert_selector(".gantt-chart-header-month", text: start_month)
  end
  def test_timeline_day_zoom_tasks_after_current_month_renders_1_month_after_last_task
    base = Date.current.beginning_of_month
    future_tasks = [
      { id: 1, name: "Task 1", start_date: base + 5.months, end_date: base + 5.months + 1.week },
      { id: 2, name: "Task 2", start_date: base + 6.months, end_date: base + 6.months + 1.week }
    ]
    render_inline(Bali::GanttChart::Component.new(tasks: future_tasks))
    end_month = month_name((base + 7.months).month)
    assert_selector(".gantt-chart-header-month", text: end_month)
  end
  # timeline - week zoom

  def test_timeline_week_zoom_renders_headers_from_2_months_before_first_task
    @options.merge!(zoom: :week)
    render_inline(component)
    start_year = (@date - 2.months).beginning_of_year.year
    assert_selector(".gantt-chart-header-year", text: start_year)
  end
  # TODO: Fix test (Issue: #289)
  # def test_timeline_week_zoom_renders_headers_2_months_after_last_task
  #   @options.merge!(zoom: :week)
  #   render_inline(component)
  #   end_year = (@date + 20.days + 2.months).end_of_year.year
  #   assert_selector(".gantt-chart-header-year", text: end_year)
  # end

  # timeline - month zoom

  def test_timeline_month_zoom_renders_headers_from_1_year_before_first_task
    @options.merge!(zoom: :month)
    render_inline(component)
    start_year = (@date - 1.year).beginning_of_year.year
    assert_selector(".gantt-chart-header-year", text: start_year)
  end
  def test_timeline_month_zoom_renders_headers_1_year_after_last_task
    @options.merge!(zoom: :month)
    render_inline(component)
    end_year = (@date + 20.days + 1.year).end_of_year.year
    assert_selector(".gantt-chart-header-year", text: end_year)
  end
end
