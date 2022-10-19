# frozen_string_literal: true

module Bali
  module GanttChart
    class Preview < ApplicationViewComponentPreview
      def default(zoom: :day)
        render GanttChart::Component.new(tasks: tasks, zoom: zoom.to_sym)
      end

      # @param zoom [Symbol] select [day, week, month]
      def view_modes(zoom: :day)
        render GanttChart::Component.new(tasks: tasks, zoom: zoom) do |c|
          c.view_mode_button label: 'Day', zoom: :day, active: zoom == :day
          c.view_mode_button label: 'Week', zoom: :week, active: zoom == :week
          c.view_mode_button label: 'Month', zoom: :month, active: zoom == :month
        end
      end

      def readonly
        render GanttChart::Component.new(tasks: tasks, readonly: true)
      end

      def custom_offset
        render GanttChart::Component.new(tasks: tasks, offset: 500)
      end

      def with_footer
        render GanttChart::Component.new(tasks: tasks) do |c|
          c.footer do
            tag.span 'This is a footer'
          end
        end
      end

      def with_list_footer
        render GanttChart::Component.new(tasks: tasks) do |c|
          c.list_footer do
            tag.span 'This is a list footer'
          end
        end
      end

      private

      def tasks
        date = Date.current

        [
          {
            id: 1, name: 'Task 1', start_date: date, end_date: date + 16.days, update_url: '/gantt_chart/1', href: '/gantt_chart/1', data: { action: 'modal#open' },
            actions: {
              info: { href: '/gantt_chart/1/edit', data: { action: 'modal#open' } },
              complete: { href: '/gantt_chart/1/complete', data: { 'turbo-method': 'patch' } },
              indent: { href: '/gantt_chart/1/indent', data: { 'turbo-method': 'patch' } },
              outdent: { href: '/gantt_chart/1/outdent', data: { 'turbo-method': 'patch' } },
              delete: { href: '/gantt_chart/1', data: { 'turbo-method': 'delete' } }
            }
          },
          {
            id: 2, name: 'Task 1.1', start_date: date, end_date: date + 10.days,
            update_url: '/gantt_chart/2', parent_id: 1, href: '/gantt_chart/2', data: { action: 'modal#open' }
          },
          {
            id: 3, name: 'Task 1.2', start_date: date + 2.days, end_date: date + 6.days,
            update_url: '/gantt_chart/3', parent_id: 1
          },
          {
            id: 4, name: 'Task 1.3', start_date: date + 6.days, end_date: date + 20.days,
            update_url: '/gantt_chart/4', parent_id: 1, progress: 60
          },
          {
            id: 5, name: 'Task 1.3.1', start_date: date + 6.days, end_date: date + 12.days,
            update_url: '/gantt_chart/5', parent_id: 4, critical: true, progress: 20
          },
          {
            id: 6, name: 'Task 1.3.2', start_date: date + 12.days, end_date: date + 20.days,
            update_url: '/gantt_chart/6', parent_id: 4, critical: true, progress: 100
          },
          {
            id: 7, name: 'Task 1.3.3', start_date: date + 14.days, end_date: date + 16.days,
            update_url: '/gantt_chart/7', parent_id: 4
          },
          {
            id: 8, name: 'Task 1.3.3.1', start_date: date + 14.days, end_date: date + 16.days,
            update_url: '/gantt_chart/8', parent_id: 7
          },
          {
            id: 9, name: 'Task 2 with a very long name with a very long ass description',
            start_date: date += 17.days, end_date: date + 2.days, update_url: '/gantt_chart/9', dependent_on_id: 7
          },
          {
            id: 10, name: 'Task 3', start_date: date += 1.day, end_date: date + 1.day,
            update_url: '/gantt_chart/10'
          },
          {
            id: 11, name: 'Task 4', start_date: date += 1.day, end_date: date + 1.day,
            update_url: '/gantt_chart/11'
          },
          {
            id: 12, name: 'Task 5', start_date: date += 1.day, end_date: date + 2.days,
            update_url: '/gantt_chart/12', dependent_on_id: 7
          },
          {
            id: 13, name: 'Milestone', start_date: date + 2.days, end_date: date + 2.days,
            update_url: '/gantt_chart/13', milestone: true
          },
          {
            id: 14, name: 'Task 6', start_date: date + 3.days, end_date: date + 3.days,
            update_url: '/gantt_chart/14'
          }
        ]
      end
    end
  end
end
