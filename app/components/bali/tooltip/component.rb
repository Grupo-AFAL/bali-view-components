# frozen_string_literal: true

module Bali
  module Tooltip
    class Component < ApplicationViewComponent
      renders_one :trigger

      POSITIONS = {
        top: 'top',
        bottom: 'bottom',
        left: 'left',
        right: 'right'
      }.freeze

      SIZES = {
        sm: 'tooltip-sm',
        md: 'tooltip-md',
        lg: 'tooltip-lg'
      }.freeze

      def initialize(trigger: 'mouseenter focus', placement: :top, size: nil, **options)
        @placement = placement&.to_sym
        @size = size&.to_sym
        @trigger_event = trigger
        @options = options
      end

      def container_classes
        class_names(
          'tooltip-component',
          'inline-block',
          @options[:class]
        )
      end

      def trigger_classes
        class_names(
          'trigger',
          'cursor-pointer'
        )
      end

      def stimulus_controller
        'tooltip'
      end

      def stimulus_values
        {
          trigger: @trigger_event,
          placement: POSITIONS[@placement] || 'top'
        }
      end
    end
  end
end
