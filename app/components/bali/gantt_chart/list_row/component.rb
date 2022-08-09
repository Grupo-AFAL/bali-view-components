# frozen_string_literal: true

module Bali
  module GanttChart
    module ListRow
      class Component < ApplicationViewComponent
        attr_reader :task

        def initialize(task:)
          @task = task
        end
      end
    end
  end
end
