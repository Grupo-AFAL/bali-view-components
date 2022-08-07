# frozen_string_literal: true

module Bali
  module GanttChart
    module Task
      class Component < ApplicationViewComponent
        attr_reader :name, :start_date, :end_date

        attr_accessor :chart_start_date, :chart_end_date

        # rubocop:disable Metrics/ParameterLists
        def initialize(
          id:,
          name:,
          start_date:,
          end_date:,
          progress: 0,
          dependent_on_id: nil,
          **options
        )
          @id = id
          @name = name
          @start_date = start_date
          @end_date = end_date
          @progress = progress
          @dependent_on_id = dependent_on_id
          @options = options
        end
        # rubocop:enable Metrics/ParameterLists

        def call
          tag.span data: {
            'gantt-chart-target': 'task',
            id: @id,
            name: @name,
            start: @start_date.to_s,
            end: @end_date.to_s,
            progress: @progress,
            dependencies: @dependent_on_id
          }
        end

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
      end
    end
  end
end
