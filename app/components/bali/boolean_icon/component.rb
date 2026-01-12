# frozen_string_literal: true

module Bali
  module BooleanIcon
    class Component < ApplicationViewComponent
      attr_reader :value, :options

      def initialize(value:, **options)
        @value = value

        @options = prepend_class_name(
          options,
          class_names('boolean-icon-component inline-flex', status_class(value))
        )
      end

      def call
        icon_name = @value ? 'check-circle' : 'times-circle'

        tag.div(**@options) do
          render Bali::Icon::Component.new(icon_name, class: 'w-5 h-5')
        end
      end

      def status_class(value)
        value ? 'text-success' : 'text-error'
      end
    end
  end
end
