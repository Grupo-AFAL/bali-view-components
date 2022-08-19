# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::GanttChart::Component, type: :component do
  before { @date = Date.current }

  let(:tasks) do
    [
      { id: 1, name: 'Task 1', start_date: @date, end_date: @date + 6.days,
        update_url: '/task/1', href: '/task/1' },
      { id: 2, name: 'Task 1.1', start_date: @date + 2.days, end_date: @date + 10.days,
        update_url: '/task/2', parent_id: 1, href: '/task/2', data: { action: 'modal#open' } },
      { id: 3, name: 'Task 1.2', start_date: @date + 2.days, end_date: @date + 10.days,
        update_url: '/task/3', parent_id: 1 },
      { id: 4, name: 'Task 1.2.1', start_date: @date + 6.days, end_date: @date + 12.days,
        update_url: '/task/4', parent_id: 3 },
      { id: 5, name: 'Task 3', start_date: @date + 6.days, end_date: @date + 12.days,
        update_url: '/task/5' },
      { id: 6, name: 'Task 4', start_date: @date + 10.days, end_date: @date + 16.days,
        update_url: '/task/6', dependent_on_id: 4 },
      { id: 7, name: 'Milestone', start_date: @date + 12.days, end_date: @date + 20.days,
        update_url: '/task/7' }
    ]
  end
  let(:options) { { tasks: tasks } }
  let(:component) { Bali::GanttChart::Component.new(**options) }

  context 'chart actions' do
    before do
      render_inline(component) do |c|
        c.view_mode_button label: 'Day', zoom: :day
        c.view_mode_button label: 'Week', zoom: :week
        c.view_mode_button label: 'Month', zoom: :month
      end
    end

    it 'renders view mode buttons' do
      expect(page).to have_css '.gantt-chart-actions .button', text: 'Day'
      expect(page).to have_css '.gantt-chart-actions .button', text: 'Week'
      expect(page).to have_css '.gantt-chart-actions .button', text: 'Month'
    end
  end

  context 'task list' do
    before { render_inline(component) }

    it 'renders the list header' do
      expect(page).to have_css '.gantt-chart-header', text: 'Name'
    end

    it 'rendes a row for every task' do
      expect(page).to have_css '.gantt-chart-row', text: 'Task 1'
      expect(page).to have_css '.gantt-chart-row', text: 'Task 1.1'
      expect(page).to have_css '.gantt-chart-row', text: 'Task 1.2'
      expect(page).to have_css '.gantt-chart-row', text: 'Task 1.2.1'
      expect(page).to have_css '.gantt-chart-row', text: 'Task 3'
      expect(page).to have_css '.gantt-chart-row', text: 'Task 4'
      expect(page).to have_css '.gantt-chart-row', text: 'Milestone'
    end

    it 'renders a arrow icon for folding parent tasks' do
      expect(page).to have_css '[data-id="1"] .chevron-down'
    end

    it 'renders a link when an href is provided with default zoom' do
      expect(page).to have_css 'a.task-name[href="/task/2?zoom=day"]', text: 'Task 1.1'
    end

    it 'renders a div when no href is provided' do
      expect(page).to have_css 'div.task-name', text: 'Task 1.2'
    end

    it 'renders a tooltip for each task' do
      expect(page).to have_css '.tooltip-component', text: 'Task 1'
    end

    it 'renders a list resizer' do
      expect(page).to have_css '.gantt-chart-list-resizer'
    end
  end

  context "task list custom zoom" do
    it 'renders a link when an href is provided with month zoom' do
      options.merge!(zoom: :month)
      render_inline(component)
      expect(page).to have_css 'a.task-name[href="/task/2?zoom=month"]', text: 'Task 1.1'
    end

    it 'renders a link when an href is provided with week zoom' do
      options.merge!(zoom: :week)
      render_inline(component)
      expect(page).to have_css 'a.task-name[href="/task/2?zoom=week"]', text: 'Task 1.1'
    end
  end

  context 'timeline' do
    it 'renders a marker for today\'s date' do
      render_inline(component)
      expect(page).to have_css '.gantt-chart-today-marker', text: 'Today'
    end

    context 'day zoom' do
      before do
        options.merge!(zoom: :day)
        render_inline(component)
        @end_date = @date + 20.days
      end

      it 'renders headers from 1 month before the first task' do
        start_month = I18n.t('date.month_names')[(@date - 1.month).beginning_of_month.month]
        expect(page).to have_css '.gantt-chart-header-month', text: start_month
      end

      it 'renders headers 1 month after the last task' do
        end_month = I18n.t('date.month_names')[(@end_date + 1.month).end_of_month.month]
        expect(page).to have_css '.gantt-chart-header-month', text: end_month
      end
    end

    context 'week zoom' do
      before do
        options.merge!(zoom: :week)
        render_inline(component)
        @end_date = @date + 20.days
      end

      it 'renders headers from 2 months before the first task' do
        start_year = (@date - 2.months).beginning_of_year.year
        expect(page).to have_css '.gantt-chart-header-year', text: start_year
      end

      it 'renders headers 2 months after the last task' do
        end_year = (@end_date + 2.months).end_of_year.year
        expect(page).to have_css '.gantt-chart-header-year', text: end_year
      end
    end

    context 'month zoom' do
      before do
        options.merge!(zoom: :month)
        render_inline(component)
        @end_date = @date + 20.days
      end

      it 'renders headers from 1 year before the first task' do
        start_year = (@date - 1.year).beginning_of_year.year
        expect(page).to have_css '.gantt-chart-header-year', text: start_year
      end

      it 'renders headers 1 year after the last task' do
        end_year = (@end_date + 1.year).end_of_year.year
        expect(page).to have_css '.gantt-chart-header-year', text: end_year
      end
    end
  end
end
