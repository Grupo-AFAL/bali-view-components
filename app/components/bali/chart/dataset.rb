# frozen_string_literal: true

module Bali
  module Chart
    class Dataset
      DEFAULT_TENSION = 0.3
      DEFAULT_BORDER_WIDTH = 2
      DEFAULT_BORDER_OPACITY = 7
      DEFAULT_BACKGROUND_OPACITY = 5
      EXTRACTED_OPTIONS = %i[tension borderWidth borderColor backgroundColor].freeze

      def initialize(label: '', data: [], order: 1, type: :bar, color: [], **options)
        @label = label
        @data = data
        @order = order
        @type = type
        @colors = Array.wrap(color)
        @options = options
      end

      def to_h
        {
          label: @label,
          data: @data,
          type: @type,
          order: @order,
          tension: @options.fetch(:tension, DEFAULT_TENSION),
          borderWidth: @options.fetch(:borderWidth, DEFAULT_BORDER_WIDTH),
          borderColor: @options.fetch(:borderColor, border_colors),
          backgroundColor: @options.fetch(:backgroundColor, background_colors),
          **extra_options
        }
      end

      # Alias for backwards compatibility
      alias result to_h

      private

      def extra_options
        @options.except(*EXTRACTED_OPTIONS)
      end

      def background_colors
        @colors.map { |c| Utils::ColorPicker.opacify(c, DEFAULT_BACKGROUND_OPACITY) }
      end

      def border_colors
        @colors.map { |c| Utils::ColorPicker.opacify(c, DEFAULT_BORDER_OPACITY) }
      end
    end
  end
end
