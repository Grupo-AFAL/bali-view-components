# frozen_string_literal: true

module Bali
  module GanttChart
    class Component < ApplicationViewComponent
      attr_reader :tasks, :row_height, :col_width, :options

      def initialize(tasks: [], row_height: 35, col_width: 25, **options)
        @tasks = tasks.map { |task| Task.new(**task) }
        tasks_by_parent_id = @tasks.group_by(&:parent_id)

        @tasks.each do |task|
          task.chart_start_date = start_date
          task.chart_end_date = end_date
          task.row_height = row_height
          task.col_width = col_width
        end

        @tasks.each { |task| task.children = tasks_by_parent_id[task.id] || [] }
        @tasks.filter! { |task| task.parent_id.blank? }

        @row_height = row_height
        @col_width = col_width

        @options = prepend_class_name(options, 'gantt-chart-component')
        @options = prepend_controller(options, 'gantt-chart')
        @options = prepend_action(options, 'sortable-list:onEnd->gantt-chart#onItemReordered')
        @options = prepend_action(options, 'interact:onResizeEnd->gantt-chart#onItemResized')
        @options = prepend_action(options, 'interact:onDragEnd->gantt-chart#onItemDragged')
        @options = prepend_action(options, 'gantt-foldable-item:toggle->gantt-chart#onFold')
        @options = prepend_values(options, 'gantt-chart', { today_offset: today_offset })
      end

      def start_date
        min_date.beginning_of_month - 1.month
      end

      def end_date
        max_date.end_of_month + 1.month
      end

      def duration
        (end_date - start_date).to_i + 1
      end

      private

      def min_date
        @min_date ||= earliest_task&.start_date || Date.current
      end

      def max_date
        @max_date ||= latest_task&.end_date || (Date.current + 2.months)
      end

      def earliest_task
        tasks.min { |a, b| a.start_date <=> b.start_date }
      end

      def latest_task
        tasks.max { |a, b| a.end_date <=> b.end_date }
      end

      def today_offset
        (start_date - Date.current).to_i.abs * col_width
      end
    end
  end
end
