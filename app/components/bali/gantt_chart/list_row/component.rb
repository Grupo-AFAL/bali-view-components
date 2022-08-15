# frozen_string_literal: true

module Bali
  module GanttChart
    module ListRow
      class Component < ApplicationViewComponent
        attr_reader :task, :readonly, :resource_name, :list_param_name, :options

        def initialize(task:, readonly:, resource_name: nil, list_param_name: 'list_id')
          @task = task
          @readonly = readonly
          @resource_name = resource_name
          @list_param_name = list_param_name

          @options = prepend_class_name(task.list_row_options, 'gantt-chart-row')
          @options = prepend_data_attribute(@options, 'id', task.id)
          @options = prepend_controller(@options, 'gantt-foldable-item')
          @options = prepend_values(@options, 'gantt-foldable-item', controller_values)
          @options = prepend_data_attribute(@options, 'sortable-update-url', task.update_url)
          @options = prepend_data_attribute(@options, 'gantt-chart-target', 'listRow')
          @options[:style] = "height: #{task.total_row_height}px"
        end

        def controller_values
          { visible: true, folded: false, parent_id: task.parent_id }
        end
      end
    end
  end
end
