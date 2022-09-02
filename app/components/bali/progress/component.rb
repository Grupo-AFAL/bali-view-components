# frozen_string_literal: true

module Bali
  module Progress
    class Component < ApplicationViewComponent
      attr_reader :value, :display_percentage, :color_code, :options

      def initialize(value: 50, display_percentage: true, color_code: default_color, **options)
        @value = value
        @display_percentage = display_percentage

        @progress_bar_color = progress_bar_color(color_code)
        @options = prepend_class_name(options, 'progress-component')
      end

      private

      def progress_bar_color(color_code)
        "--progress-value-bar-color: #{color_code};"
      end

      def default_color
        'hsl(196, 82%, 78%)'
      end
    end
  end
end
