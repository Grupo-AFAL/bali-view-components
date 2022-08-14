# frozen_string_literal: true

module Bali
  module GanttChart
    class Component < ApplicationViewComponent
      attr_reader :tasks, :row_height, :col_width, :zoom, :readonly, :resource_name, :options

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        tasks: [],
        row_height: 35,
        col_width: nil,
        zoom: :day,
        readonly: false,
        offset: nil,
        resource_name: nil,
        **options
      )
        @row_height = row_height
        @col_width = col_width
        @zoom = zoom&.to_sym || :day

        # Default is 100 for month and week view and 25 for day view.
        @col_width ||= @zoom == :day ? 25 : 100
        @readonly = readonly
        @offset = offset
        @resource_name = resource_name

        @default_min_date = Date.current - 2.months
        @default_max_date = Date.current + 2.months

        @tasks = tasks.map { |task| Task.new(**task) }
        tasks_by_parent_id = @tasks.group_by(&:parent_id)
        @tasks.each do |task|
          task.chart_start_date = start_date
          task.chart_end_date = end_date
          task.row_height = @row_height
          task.col_width = @col_width
          task.zoom = @zoom
          task.children = tasks_by_parent_id[task.id] || []
        end
        @tasks.filter! { |task| task.parent_id.blank? }

        @options = prepend_class_name(options, 'gantt-chart-component')
        @options = prepend_class_name(options, "#{@zoom}-zoom")
        @options = prepend_controller(@options, 'gantt-chart')
        @options = prepend_action(@options, 'sortable-list:onEnd->gantt-chart#onItemReordered')
        @options = prepend_action(@options, 'interact:onResizing->gantt-chart#onItemResizing')
        @options = prepend_action(@options, 'interact:onResizeEnd->gantt-chart#onItemResized')
        @options = prepend_action(@options, 'interact:onDragging->gantt-chart#onItemDragging')
        @options = prepend_action(@options, 'interact:onDragEnd->gantt-chart#onItemDragged')
        @options = prepend_action(@options, 'gantt-foldable-item:toggle->gantt-chart#onFold')
        @options = prepend_values(@options, 'gantt-chart', controller_values)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/ParameterLists

      def controller_values
        {
          resource_name: resource_name,
          offset: offset,
          today_offset: today_offset,
          row_height: row_height,
          col_width: col_width,
          zoom: zoom
        }
      end

      def offset
        @offset || (today_offset - col_width)
      end

      def start_date
        case zoom
        when :day
          (min_date - 1.month).beginning_of_month
        when :week
          (min_date - 2.months).beginning_of_week
        when :month
          (min_date - 1.year).beginning_of_year
        end
      end

      def end_date
        case zoom
        when :day
          (max_date + 1.month).end_of_month
        when :week
          (max_date + 2.months).end_of_week
        when :month
          (max_date + 1.year).end_of_year
        end
      end

      def duration
        case zoom
        when :day
          duration_in_days
        when :week
          duration_in_days / 7
        when :month
          duration_in_months
        end
      end

      private

      def duration_in_days
        (end_date - start_date).to_f + 1
      end

      def duration_in_months
        end_month = (end_date.year * 12) + end_date.month
        start_month = (start_date.year * 12) + start_date.month
        (end_month - start_month).to_i + 1
      end

      def min_date
        @min_date ||= earliest_task&.start_date || @default_min_date
      end

      def max_date
        @max_date ||= [latest_task&.end_date, @default_max_date].compact.max
      end

      def earliest_task
        tasks.min { |a, b| a.start_date <=> b.start_date }
      end

      def latest_task
        tasks.max { |a, b| a.end_date <=> b.end_date }
      end

      def today_offset
        case zoom
        when :day
          days_to_today * col_width
        when :week
          (days_to_today / 7) * col_width
        when :month
          months_to_today * col_width
        end
      end

      def days_to_today
        (start_date - Date.current).to_f.abs
      end

      def months_to_today
        start_month = (start_date.year * 12) + start_date.month
        current_month = (Date.current.year * 12) + Date.current.month
        (start_month - current_month).to_i.abs + (Date.current.day / 30.0)
      end
    end
  end
end
