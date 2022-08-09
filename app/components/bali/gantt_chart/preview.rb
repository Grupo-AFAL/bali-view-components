# frozen_string_literal: true

module Bali
  module GanttChart
    class Preview < ApplicationViewComponentPreview
      def default
        date = Date.current

        tasks = [
          { id: 1, name: 'Task 1', start_date: date, end_date: date + 2.days,
            update_url: '/gantt_chart/1' },
          { id: 6, name: 'Task 1a', start_date: date, end_date: date + 2.days,
            update_url: '/gantt_chart/6', parent_id: 1 },
          { id: 7, name: 'Task 1b', start_date: date + 2.days, end_date: date + 4.days,
            update_url: '/gantt_chart/7', parent_id: 1 },
          { id: 8, name: 'Task 1c', start_date: date + 4.days, end_date: date + 6.days,
            update_url: '/gantt_chart/8', parent_id: 1 },
          { id: 2, name: 'Task 2', start_date: date, end_date: date + 4.days,
            update_url: '/gantt_chart/2' },
          { id: 3, name: 'Task 3', start_date: date += 1.day, end_date: date + 1.day,
            update_url: '/gantt_chart/3' },
          { id: 4, name: 'Task 4', start_date: date += 1.day, end_date: date + 1.day,
            update_url: '/gantt_chart/4' },
          { id: 5, name: 'Task 5', start_date: date += 1.day, end_date: date + 2.days,
            update_url: '/gantt_chart/5' }
        ]

        render GanttChart::Component.new(tasks: tasks)
      end
    end
  end
end
