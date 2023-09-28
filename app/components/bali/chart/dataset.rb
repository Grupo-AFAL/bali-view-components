# frozen_string_literal: true

module Bali
  module Chart
    class Dataset
      LINE_GRAPH_TENSION = 0.3

      def initialize(label: '', data: {}, order: 1, type: :bar, **options) 
        @label = label
        @data = data
        @order = order
        @type = type
        @color = Array.wrap(options.delete(:color))
        @options = options
      end

      def result
        {
          label: @label,
          data: @data,
          type: @type,
          order: @order,
          tension: @options.delete(:tension) ||  LINE_GRAPH_TENSION,
          borderWidth: @options.delete(:borderWidth) || 2,
          borderColor: @options.delete(:borderColor) || border_color,
          backgroundColor: @options.delete(:backgroundColor) || background_color,
          **@options
        }
      end

      private

      def background_color
        @background_color ||= @color.map { |color| Utils::ColorPicker.opacify(color) }
      end

      def border_color
        @border_color ||= @color.map { |color| Utils::ColorPicker.opacify(color, 7) }
      end
    end
  end
end
