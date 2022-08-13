# frozen_string_literal: true

module Bali
  module GanttChart
    module TimelineRow
      class Component < ApplicationViewComponent
        attr_reader :task, :readonly, :task_name_padding

        def initialize(task:, readonly:)
          @task = task
          @readonly = readonly
          @task_name_padding = 8
        end
      end
    end
  end
end
