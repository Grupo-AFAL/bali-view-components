# frozen_string_literal: true

module Bali
  module GanttChart
    class Preview < ApplicationViewComponentPreview
      def default
        date = Date.current

        tasks = [
          { id: 1, name: 'Task 1', start_date: date, end_date: date + 2.days, update_url: '/gantt_chart/1' },
          { id: 2, name: 'Task 1.1', start_date: date, end_date: date + 2.days, update_url: '/gantt_chart/2', parent_id: 1 },
          { id: 3, name: 'Task 1.2', start_date: date + 2.days, end_date: date + 4.days, update_url: '/gantt_chart/3', parent_id: 1 },
          { id: 4, name: 'Task 1.3', start_date: date + 4.days, end_date: date + 6.days, update_url: '/gantt_chart/4', parent_id: 1 },
          { id: 5, name: 'Task 1.3.1', start_date: date + 4.days, end_date: date + 6.days, update_url: '/gantt_chart/5', parent_id: 4 },
          { id: 6, name: 'Task 1.3.2', start_date: date + 4.days, end_date: date + 6.days, update_url: '/gantt_chart/6', parent_id: 4 },
          { id: 7, name: 'Task 1.3.3', start_date: date + 4.days, end_date: date + 6.days, update_url: '/gantt_chart/7', parent_id: 4 },
          { id: 8, name: 'Task 2', start_date: date, end_date: date + 4.days, update_url: '/gantt_chart/8' },
          { id: 9, name: 'Task 3', start_date: date += 1.day, end_date: date + 1.day, update_url: '/gantt_chart/9' },
          { id: 10, name: 'Task 4', start_date: date += 1.day, end_date: date + 1.day, update_url: '/gantt_chart/10' },
          { id: 11, name: 'Task 5', start_date: date += 1.day, end_date: date + 2.days, update_url: '/gantt_chart/11' }
        ]

        render GanttChart::Component.new(tasks: tasks)
      end
    end
  end
end
