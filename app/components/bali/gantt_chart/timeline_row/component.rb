# frozen_string_literal: true

module Bali
  module GanttChart
    module TimelineRow
      class Component < ApplicationViewComponent
        attr_reader :task, :readonly, :zoom, :options

        def initialize(task:, readonly:, zoom:)
          @task = task
          @readonly = readonly
          @zoom = zoom

          @options = prepend_class_name(task.row_options, 'gantt-chart-row')
          @options = prepend_data_attribute(@options, 'id', task.id)
          @options = prepend_data_attribute(@options, 'gantt-chart-target', 'timelineRow')
          @options = prepend_data_attribute(@options, 'dependent-on-id', task.dependent_on_id)
          @options[:style] = "height: #{task.total_row_height}px"
        end
      end
    end
  end
end
