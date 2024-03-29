# frozen_string_literal: true

module Bali
  module GanttChart
    module DragHandle
      class Component < ApplicationViewComponent
        attr_reader :task, :draggable, :tag_name, :options

        def initialize(task:, draggable:)
          @task = task
          @draggable = draggable
          @tag_name = :div

          @options = prepend_class_name(task.drag_options, component_class_names)

          if task.href.present?
            @tag_name = :a
            @options[:href] = task.href

            # To set the scroll offset query param throught JS on the link
            @options = prepend_data_attribute(@options, 'gantt-chart-target', 'taskLink')
            @options = prepend_action(@options, 'click->interact#onClick')
          end

          return unless draggable

          @options = prepend_action(@options, 'mousedown->interact#onDragStart')
          @options = prepend_data_attribute(@options, 'interact-target', 'link')
        end

        def component_class_names
          class_names('gantt-chart-drag-handle', 'non-draggable': !draggable)
        end
      end
    end
  end
end
