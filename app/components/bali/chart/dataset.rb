# frozen_string_literal: true

module Bali
  module Chart
    class Dataset
      DEFAULT_TENSION = 0.3
      DEFAULT_BORDER_WIDTH = 2
      DEFAULT_BORDER_OPACITY = 0.8
      DEFAULT_BACKGROUND_OPACITY = 0.5
      DEFAULT_BORDER_RADIUS = 6
      DEFAULT_POINT_RADIUS = 4
      DEFAULT_POINT_HOVER_RADIUS = 6
      EXTRACTED_OPTIONS = %i[tension borderWidth borderColor backgroundColor rounded pointRadius
                             pointHoverRadius].freeze

      # rubocop:disable Metrics/ParameterLists
      def initialize(label: '', data: [], order: 1, type: :bar, color: [], rounded: false,
                     **options)
        # rubocop:enable Metrics/ParameterLists
        @label = label
        @data = data
        @order = order
        @type = type
        @colors = Array.wrap(color)
        @rounded = rounded
        @options = options
      end

      def to_h
        result = {
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

        # Add rounded corners for bar charts
        if @rounded
          result[:borderRadius] = @options.fetch(:borderRadius, DEFAULT_BORDER_RADIUS)
          result[:borderSkipped] = false # Round all corners
        end

        # Add point styling for line charts
        if line_chart?
          result[:pointRadius] = @options.fetch(:pointRadius, DEFAULT_POINT_RADIUS)
          result[:pointHoverRadius] = @options.fetch(:pointHoverRadius, DEFAULT_POINT_HOVER_RADIUS)
          result[:pointBackgroundColor] = @options.fetch(:pointBackgroundColor, border_colors.first)
          result[:pointBorderColor] = '#ffffff'
          result[:pointBorderWidth] = 2
        end

        result
      end

      # Alias for backwards compatibility
      alias result to_h

      private

      def line_chart?
        @type.to_sym == :line
      end

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
