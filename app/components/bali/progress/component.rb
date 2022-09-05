# frozen_string_literal: true

module Bali
  module Progress
    class Component < ApplicationViewComponent
      attr_reader :value, :percentage, :color_code, :options

      def initialize(value: 50, percentage: true, color_code: default_color, **options)
        @value = value
        @percentage = percentage

        @bar_color = bar_color(color_code)
        @options = prepend_class_name(options, 'progress-component')
      end

      private

      def bar_color(color_code)
        "--progress-value-bar-color: #{color_code};"
      end

      def default_color
        'hsl(196, 82%, 78%)'
      end
    end
  end
end
