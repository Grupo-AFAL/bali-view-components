# frozen_string_literal: true

module Bali
  module GanttChart
    class Component < ApplicationViewComponent
      attr_reader :tasks, :row_height, :col_width, :zoom, :options

      # rubocop:disable Metrics/AbcSize
      def initialize(tasks: [], row_height: 35, col_width: nil, zoom: :day, **options)
        @row_height = row_height
        @col_width = col_width

        # Default is 100 for month view and 25 for day view.
        @col_width ||= zoom == :day ? 25 : 100
        @zoom = zoom

        @tasks = tasks.map { |task| Task.new(**task) }
        tasks_by_parent_id = @tasks.group_by(&:parent_id)
        @tasks.each do |task|
          task.chart_start_date = start_date
          task.chart_end_date = end_date
          task.row_height = @row_height
          task.col_width = @col_width
          task.zoom = zoom
          task.children = tasks_by_parent_id[task.id] || []
        end
        @tasks.filter! { |task| task.parent_id.blank? }

        @options = prepend_class_name(options, 'gantt-chart-component')
        @options = prepend_class_name(options, 'month-zoom') if zoom == :month
        @options = prepend_controller(@options, 'gantt-chart')
        @options = prepend_action(@options, 'sortable-list:onEnd->gantt-chart#onItemReordered')
        @options = prepend_action(@options, 'interact:onResizing->gantt-chart#onItemResizing')
        @options = prepend_action(@options, 'interact:onResizeEnd->gantt-chart#onItemResized')
        @options = prepend_action(@options, 'interact:onDragging->gantt-chart#onItemDragging')
        @options = prepend_action(@options, 'interact:onDragEnd->gantt-chart#onItemDragged')
        @options = prepend_action(@options, 'gantt-foldable-item:toggle->gantt-chart#onFold')
        @options = prepend_values(@options, 'gantt-chart', {
                                    today_offset: today_offset, row_height: row_height
                                  })
      end
      # rubocop:enable Metrics/AbcSize

      def start_date
        if zoom == :day
          (min_date - 1.month).beginning_of_month
        elsif zoom == :month
          (min_date - 1.year).beginning_of_year
        end
      end

      def end_date
        if zoom == :day
          (max_date + 1.month).end_of_month
        elsif zoom == :month
          (max_date + 1.year).end_of_year
        end
      end

      def duration
        if zoom == :day
          (end_date - start_date).to_i + 1
        else
          end_month = (end_date.year * 12) + end_date.month
          start_month = (start_date.year * 12) + start_date.month
          (end_month - start_month).to_i + 1
        end
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
        if zoom == :day
          (start_date - Date.current).to_i.abs * col_width
        else
          start_month = (start_date.year * 12) + start_date.month
          current_month = (Date.current.year * 12) + Date.current.month
          (start_month - current_month).to_i.abs * col_width
        end
      end
    end
  end
end
