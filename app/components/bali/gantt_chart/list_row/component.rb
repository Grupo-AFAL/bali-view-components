# frozen_string_literal: true

module Bali
  module GanttChart
    module ListRow
      class Component < ApplicationViewComponent
        attr_reader :task, :readonly

        def initialize(task:, readonly:)
          @task = task
          @readonly = readonly
        end
      end
    end
  end
end
