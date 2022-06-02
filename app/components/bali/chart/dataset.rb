module Bali
  module Chart
    class Dataset
      LINE_GRAPH_TENSION = 0.3

      def initialize(type, values, label, order, axis, colors)
        @type = type
        @values = values
        @label = label
        @order = order
        @axis = axis
        @colors = colors
        @color_picker = ColorPicker.new
      end

      def result
          {
            label: @label,
            data: @values,
            borderWidth: 2,
            yAxisID: @axis,
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