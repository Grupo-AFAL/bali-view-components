module Bali
  module GanttChart
    module TimelineRow
      class Component < ApplicationViewComponent
        attr_reader :task

        def initialize(task:)
          @task = task
        end
      end
    end
  end
end
