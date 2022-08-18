# frozen_string_literal: true

module Bali
  module GanttChart
    module DragHandle
      class Component < ApplicationViewComponent
        attr_reader :task, :draggable, :readonly, :tag_name, :options

        def initialize(task:, draggable:, readonly:)
          @task = task
          @draggable = draggable
          @tag_name = :div

          task.drag_options[:data]&.delete(:action) if readonly

          @options = prepend_class_name(task.drag_options, component_class_names)
          @options = prepend_action(@options, 'mousedown->interact#onDragStart') if draggable

          return if task.href.blank? || readonly

          @tag_name = :a
          @options[:href] = task.href
          @options = prepend_action(@options, 'click->interact#onClick')
          @options = prepend_data_attribute(@options, 'interact-target', 'link')
          @options = prepend_data_attribute(@options, 'gantt-chart-target', 'taskLink')
        end

        def component_class_names
          class_names('gantt-chart-drag-handle', 'non-draggable': !draggable)
        end
      end
    end
  end
end
