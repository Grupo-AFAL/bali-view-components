# frozen_string_literal: true

module Bali
  module GanttChart
    module DragHandle
      class Component < ApplicationViewComponent
        attr_reader :task, :tag_name, :options

        def initialize(task:)
          @task = task
          @tag_name = :div

          @options = {
            class: 'gantt-chart-drag-handle',
            data: {
              action: 'mousedown->interact#onDragStart'
            }
          }

          return if task.href.blank?

          @tag_name = :a
          @options[:href] = task.href
          @options = prepend_action(@options, 'click->interact#onClick')
          @options = prepend_data_attribute(@options, 'interact-target', 'link')
        end
      end
    end
  end
end
