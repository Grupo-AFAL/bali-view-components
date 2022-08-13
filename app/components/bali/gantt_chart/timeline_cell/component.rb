# frozen_string_literal: true

module Bali
  module GanttChart
    module TimelineCell
      class Component < ApplicationViewComponent
        attr_reader :task, :readonly, :zoom, :task_name_padding

        def initialize(task:, readonly:, zoom:)
          @task = task
          @readonly = readonly
          @zoom = zoom
          @task_name_padding = 8
        end

        def resize_handle?
          @resize_handle ||= draggable? && !task.milestone?
        end

        def draggable?
          @draggable ||= task.children.empty? && !readonly && zoom == :day
        end
      end
    end
  end
end
