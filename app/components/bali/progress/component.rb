# frozen_string_literal: true

module Bali
  module Progress
    class Component < ApplicationViewComponent
      attr_reader :value, :display_percentage, :options

      def initialize(value: 50, display_percentage: true, **options)
        @value = value
        @display_percentage = display_percentage

        @options = prepend_class_name(options, 'progress-component')
      end
    end
  end
end
