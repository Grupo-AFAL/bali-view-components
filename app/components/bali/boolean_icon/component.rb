# frozen_string_literal: true

module Bali
  module BooleanIcon
    class Component < ApplicationViewComponent
      attr_reader :value, :options

      def initialize(value:, **options)
        @value = value

        @options = prepend_class_name(
          options,
          class_names('boolean-icon-component', status_class(value))
        )
      end

      def call
        icon_name = @value ? 'check-circle' : 'times-circle'

        tag.div(**@options) do
          render Bali::Icon::Component.new(icon_name)
        end
      end

      def status_class(value)
        value ? 'has-text-success' : 'has-text-danger'
      end
    end
  end
end
