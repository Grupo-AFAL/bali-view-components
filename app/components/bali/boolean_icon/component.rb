# frozen_string_literal: true

module Bali
  module BooleanIcon
    class Component < ApplicationViewComponent
      ICONS = {
        true => 'check-circle',
        false => 'times-circle'
      }.freeze

      STATUS_CLASSES = {
        true => 'text-success',
        false => 'text-error'
      }.freeze

      # @param value [Boolean, nil] The boolean value to display
      # @param options [Hash] Additional HTML attributes passed to the wrapper div
      def initialize(value:, **options)
        @value = coerce_to_boolean(value)
        @options = prepend_class_name(options, component_classes)
      end

      def call
        tag.div(**@options) do
          render Bali::Icon::Component.new(icon_name, class: 'w-5 h-5')
        end
      end

      private

      # Coerce value to boolean, treating nil as false.
      # This is a conversion method, not a predicate.
      # rubocop:disable Naming/PredicateMethod
      def coerce_to_boolean(value)
        !!value
      end
      # rubocop:enable Naming/PredicateMethod

      def icon_name
        ICONS[@value]
      end

      def component_classes
        class_names('boolean-icon-component inline-flex', STATUS_CLASSES[@value])
      end
    end
  end
end
