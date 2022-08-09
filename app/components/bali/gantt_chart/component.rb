# frozen_string_literal: true

module Bali
  module GanttChart
    class Component < ApplicationViewComponent
      attr_reader :tasks, :row_height, :col_width, :options

      # rubocop:disable Metrics/AbcSize
      def initialize(tasks: [], row_height: 35, col_width: 25, **options)
        @row_height = row_height
        @col_width = col_width

        @tasks = tasks.map { |task| Task.new(**task) }
        tasks_by_parent_id = @tasks.group_by(&:parent_id)
        @tasks.each do |task|
          task.chart_start_date = start_date
          task.chart_end_date = end_date
          task.row_height = row_height
          task.col_width = col_width
          task.children = tasks_by_parent_id[task.id] || []
        end
        @tasks.filter! { |task| task.parent_id.blank? }

        @options = configure_options(options)
      end
      # rubocop:enable Metrics/AbcSize

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

      def configure_options(opts)
        opts = prepend_class_name(opts, 'gantt-chart-component')
        opts = prepend_controller(opts, 'gantt-chart')
        opts = prepend_action(opts, 'sortable-list:onEnd->gantt-chart#onItemReordered')
        opts = prepend_action(opts, 'interact:onResizeEnd->gantt-chart#onItemResized')
        opts = prepend_action(opts, 'interact:onDragEnd->gantt-chart#onItemDragged')
        opts = prepend_action(opts, 'gantt-foldable-item:toggle->gantt-chart#onFold')
        prepend_values(opts, 'gantt-chart', { today_offset: today_offset })
      end
    end
  end
end
