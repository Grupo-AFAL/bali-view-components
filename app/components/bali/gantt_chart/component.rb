# frozen_string_literal: true

module Bali
  module GanttChart
    class Component < ApplicationViewComponent
      attr_reader :options

      def initialize(**options)
        @options = prepend_class_name(options, 'gantt_chart-component')
        @options = prepend_controller(options, 'gantt-chart')
      end
    end
  end
end
