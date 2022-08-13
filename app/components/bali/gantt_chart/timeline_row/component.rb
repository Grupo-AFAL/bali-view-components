# frozen_string_literal: true

module Bali
  module GanttChart
    module TimelineRow
      class Component < ApplicationViewComponent
        attr_reader :task, :readonly, :zoom

        def initialize(task:, readonly:, zoom:)
          @task = task
          @readonly = readonly
          @zoom = zoom
        end
      end
    end
  end
end
