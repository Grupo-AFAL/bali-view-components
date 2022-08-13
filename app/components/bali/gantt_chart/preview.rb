# frozen_string_literal: true

module Bali
  module GanttChart
    class Preview < ApplicationViewComponentPreview

      def default(zoom: :day)
        render GanttChart::Component.new(tasks: tasks, zoom: zoom.to_sym)
      end

      def month_view
        render GanttChart::Component.new(tasks: tasks, zoom: :month)
      end

      def week_view
        render GanttChart::Component.new(tasks: tasks, zoom: :week)
      end

      def readonly
        render GanttChart::Component.new(tasks: tasks, readonly: true)
      end

      def custom_offset
        render GanttChart::Component.new(tasks: tasks, offset: 500)
      end

      private

      def tasks
        date = Date.current

        [
          { id: 1, name: 'Task 1', start_date: date, end_date: date + 16.days, update_url: '/gantt_chart/1', href: '/gantt_chart/1', data: { action: 'modal#open' } },
          { id: 2, name: 'Task 1.1', start_date: date, end_date: date + 2.days, update_url: '/gantt_chart/2', parent_id: 1, href: '/gantt_chart/2', data: { action: 'modal#open' } },
          { id: 3, name: 'Task 1.2', start_date: date + 2.days, end_date: date + 6.days, update_url: '/gantt_chart/3', parent_id: 1 },
          { id: 4, name: 'Task 1.3', start_date: date + 6.days, end_date: date + 16.days, update_url: '/gantt_chart/4', parent_id: 1 },
          { id: 5, name: 'Task 1.3.1', start_date: date + 6.days, end_date: date + 12.days, update_url: '/gantt_chart/5', parent_id: 4 },
          { id: 6, name: 'Task 1.3.2', start_date: date + 10.days, end_date: date + 14.days, update_url: '/gantt_chart/6', parent_id: 4 },
          { id: 7, name: 'Task 1.3.3', start_date: date + 14.days, end_date: date + 16.days, update_url: '/gantt_chart/7', parent_id: 4 },
          { id: 8, name: 'Task 1.3.3.1', start_date: date + 14.days, end_date: date + 16.days, update_url: '/gantt_chart/7', parent_id: 7 },
          { id: 9, name: 'Task 2 with a very long name', start_date: date += 17.days, end_date: date + 2.days, update_url: '/gantt_chart/8', dependent_on_id: 7 },
          { id: 10, name: 'Task 3', start_date: date += 1.day, end_date: date + 1.day, update_url: '/gantt_chart/9' },
          { id: 11, name: 'Task 4', start_date: date += 1.day, end_date: date + 1.day, update_url: '/gantt_chart/10' },
          { id: 12, name: 'Task 5', start_date: date += 1.day, end_date: date + 2.days, update_url: '/gantt_chart/11', dependent_on_id: 7 },
          { id: 13, name: 'Milestone', start_date: date + 2.days, end_date: date + 2.days, update_url: '/gantt_chart/12' }
        ]
      end
    end
  end
end
