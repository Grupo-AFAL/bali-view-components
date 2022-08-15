# frozen_string_literal: true

module Bali
  module GanttChart
    class Task
      attr_reader :id, :name, :href, :start_date, :end_date, :update_url, :parent_id,
                  :dependent_on_id, :options

      attr_accessor :chart_start_date, :chart_end_date, :children, :row_height, :col_width, :zoom

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        id:,
        name:,
        start_date:,
        end_date:,
        parent_id: nil,
        href: nil,
        update_url: nil,
        children: [],
        progress: 0,
        dependent_on_id: nil,
        **options
      )
        @id = id
        @name = name
        @start_date = start_date
        @end_date = end_date
        @parent_id = parent_id
        @href = href
        @update_url = update_url
        @children = children
        @progress = progress
        @dependent_on_id = dependent_on_id
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def position_left
        offset * col_width
      end

      def width
        duration * col_width
      end

      def params
        {
          id: id,
          parent_id: parent_id,
          name: name,
          start_date: start_date,
          end_date: end_date,
          update_url: update_url
        }
      end

      def total_row_height
        (child_count + 1) * row_height
      end

      def child_count
        children.size + children.sum(&:child_count)
      end

      def milestone?
        start_date == end_date
      end

      def row_options
        @row_options ||= options[:row] || {}
      end

      def cell_options
        @cell_options ||= options[:cell] || {}
      end

      def drag_options
        @drag_options ||= options[:drag] || {}
      end

      def list_row_options
        @list_row_options ||= options[:list_row] || {}
      end

      def list_task_name_options
        @list_task_name_options ||= options[:list_task_name] || {}
      end

      private

      def duration
        case zoom
        when :day
          duration_in_days
        when :week
          duration_in_days / 7
        when :month
          duration_in_days / 30
        end
      end

      def duration_in_days
        (end_date - start_date).to_f + 1
      end

      def offset
        case zoom
        when :day
          offset_in_days
        when :week
          offset_in_days / 7
        when :month
          offset_in_months
        end
      end

      def offset_in_days
        (start_date - chart_start_date).to_f
      end

      def offset_in_months
        start_month = (start_date.year * 12) + start_date.month
        chart_start_month = (chart_start_date.year * 12) + chart_start_date.month
        (start_month - chart_start_month).to_i + (start_date.day.to_f / 30)
      end
    end
  end
end
