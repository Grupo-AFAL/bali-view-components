# frozen_string_literal: true

module Bali
  module Progress
    class Component < ApplicationViewComponent
      COLORS = {
        primary: 'progress-primary',
        secondary: 'progress-secondary',
        accent: 'progress-accent',
        neutral: 'progress-neutral',
        info: 'progress-info',
        success: 'progress-success',
        warning: 'progress-warning',
        error: 'progress-error'
      }.freeze

      def initialize(value: 0, max: 100, color: nil, show_percentage: true, **options)
        @value = value
        @max = max
        @color = color&.to_sym
        @show_percentage = show_percentage
        @options = options
      end

      def show_percentage?
        @show_percentage
      end

      def percentage_value
        return 0 if @max.zero?

        ((@value.to_f / @max) * 100).round
      end

      private

      attr_reader :value, :max, :options

      def wrapper_classes
        class_names(
          'flex items-center gap-2',
          options[:class]
        )
      end

      def wrapper_attributes
        options.except(:class)
      end

      def progress_classes
        class_names(
          'progress',
          'w-full',
          COLORS[@color]
        )
      end
    end
  end
end
