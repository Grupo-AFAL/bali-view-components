# frozen_string_literal: true

module Bali
  module GanttChart
    class Task
      attr_reader :id, :name, :start_date, :end_date, :update_url, :parent_id

      attr_accessor :chart_start_date, :chart_end_date, :children

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        id:,
        name:,
        start_date:,
        end_date:,
        parent_id: nil,
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
        @update_url = update_url
        @children = children
        @progress = progress
        @dependent_on_id = dependent_on_id
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def position_left
        offset * GanttChart::Component::COLUMN_WIDTH
      end

      def width
        duration * GanttChart::Component::COLUMN_WIDTH
      end

      def duration
        (end_date - start_date).to_i + 1
      end

      def offset
        (start_date - chart_start_date).to_i
      end

      def params
        {
          id: id,
          name: name,
          start_date: start_date,
          end_date: end_date,
          update_url: update_url
        }
      end
    end
  end
end
