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

      CONTROLLER = 'tooltip'

      # NOTE: The `trigger_event` parameter is named to avoid collision with the `trigger` slot
      def initialize(placement: :top, trigger_event: 'mouseenter focus', **options)
        @placement = placement&.to_sym
        @trigger_event = trigger_event
        @options = options
      end

      def container_classes
        class_names(
          'tooltip-component',
          'inline-block',
          options[:class]
        )
      end

      def container_attributes
        options.except(:class).merge(
          data: stimulus_data.merge(options.fetch(:data, {}))
        )
      end

      def trigger_classes
        class_names('trigger', 'cursor-pointer')
      end

      private

      attr_reader :placement, :trigger_event, :options

      def stimulus_data
        {
          controller: CONTROLLER,
          "#{CONTROLLER}-placement-value": placement_value,
          "#{CONTROLLER}-trigger-value": trigger_event
        }
      end

      def placement_value
        POSITIONS.fetch(placement, 'top')
      end
    end
  end
end
