# frozen_string_literal: true

module Bali
  module GanttChart
    module TaskActions
      class Component < ApplicationViewComponent
        attr_reader :task

        def initialize(task:)
          @task = task
        end

        def render?
          task.actions_enabled?
        end
      end
    end
  end
end
