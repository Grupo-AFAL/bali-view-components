# frozen_string_literal: true

module Bali
  module Chart
    class Dataset
      DEFAULT_TENSION = 0.3
      DEFAULT_BORDER_WIDTH = 2
      DEFAULT_BORDER_OPACITY = 0.8
      DEFAULT_BACKGROUND_OPACITY = 0.5
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
        @colors.map { |c| apply_alpha(c, DEFAULT_BACKGROUND_OPACITY) }
      end

      def border_colors
        @colors.map { |c| apply_alpha(c, DEFAULT_BORDER_OPACITY) }
      end

      # Apply alpha to a color, handling hex, var(), and oklch formats
      def apply_alpha(color, alpha)
        if css_var_color?(color)
          # For var(--color-*) format, use color-mix for transparency
          "color-mix(in oklch, #{color} #{(alpha * 100).to_i}%, transparent)"
        elsif oklch_color?(color)
          # For oklch(var(...)) format, add alpha
          color.sub(/\)$/, " / #{alpha})")
        else
          # Legacy hex color handling
          Utils::ColorPicker.opacify(color, (alpha * 10).to_i)
        end
      end

      def css_var_color?(color)
        color.to_s.start_with?('var(')
      end

      def oklch_color?(color)
        color.to_s.start_with?('oklch(')
      end
    end
  end
end
