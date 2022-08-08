# frozen_string_literal: true

module Bali
  module GanttChart
    class Preview < ApplicationViewComponentPreview
      def default
        date = Date.current

        render GanttChart::Component.new do |c|
          c.task(id: 1, name: 'Task 1', start_date: date, end_date: date + 2.days, update_url: '/gantt_chart/1')
          c.task(id: 2, name: 'Task 2', start_date: date, end_date: date + 4.days, update_url: '/gantt_chart/2')
          c.task(id: 3, name: 'Task 3', start_date: date += 1.day, end_date: date + 1.day, update_url: '/gantt_chart/3')
          c.task(id: 4, name: 'Task 4', start_date: date += 1.day, end_date: date + 1.day, update_url: '/gantt_chart/4')
          c.task(id: 5, name: 'Task 5', start_date: date += 1.day, end_date: date + 2.days, update_url: '/gantt_chart/5')
        end
      end
    end
  end
end