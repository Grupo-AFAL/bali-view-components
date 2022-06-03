# frozen_string_literal: true

module Bali
  module Chart
    class Dataset
      LINE_GRAPH_TENSION = 0.3

      def initialize(type, values, colors, **options)
        @type = type
        @values = values
        @colors = colors
        @label = options.delete(:label) || ''
        @order = options.delete(:order) || 1
        @axis = options.delete(:axis) || 1
        @color_picker = ColorPicker.new
      end

      def result
        {
          label: @label,
          data: @values,
          borderWidth: 2,
          yAxisID: "y_#{@axis}",
          type: @type,
          order: @order,
          tension: LINE_GRAPH_TENSION,
          backgroundColor: background_colors,
          borderColor: border_colors
        }
      end

      private

      def background_colors
        @background_colors ||= @colors.map { |color| @color_picker.opacify(color) }
      end

      def border_colors
        @border_colors ||= @colors.map { |color| @color_picker.opacify(color, 7) }
      end
    end
  end
end
