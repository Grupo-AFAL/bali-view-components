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

      def initialize(value:, **options)
        @value = value
        @options = prepend_class_name(options, component_classes)
      end

      def call
        tag.div(**@options) do
          render Bali::Icon::Component.new(ICONS[@value], class: 'w-5 h-5')
        end
      end

      private

      def component_classes
        class_names('boolean-icon-component inline-flex', STATUS_CLASSES[@value])
      end
    end
  end
end
