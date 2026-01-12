# frozen_string_literal: true

module Bali
  module Heatmap
    class Component < ApplicationViewComponent
      attr_reader :data, :width, :height, :gradient_colors, :options

      renders_one :hovercard_title, ->(text) { tag.p(text, class: 'text-xs font-bold mb-0') }
      renders_one :legend_title, ->(text) { tag.p(text, class: 'text-xs font-bold') }
      renders_one :y_axis_title, ->(text) { tag.p(text, class: 'text-xs font-bold pb-3') }
      renders_one :x_axis_title, ->(text) {
                                   tag.p(text, class: 'text-xs font-bold mt-2 text-center')
                                 }

      def initialize(width: 480, height: 480, data: {}, color: '#008806', **options)
        @width = width
        @height = height
        @data = data
        @color = color
        @gradient_colors = Bali::Utils::ColorPicker.gradient(@color)
        @options = prepend_class_name(options, 'heatmap-component')
      end

      def max_value
        @max_value ||= values.max
      end

      def labels_x
        @labels_x ||= data.keys
      end

      def labels_y
        return @labels_y if defined? @labels_y

        flatten_labels = data.values.flat_map(&:keys)
        @labels_y = flatten_labels.size.positive? ? (flatten_labels.min..flatten_labels.max) : [0]
      end

      def values
        @values ||= data.values.flat_map(&:values)
      end

      def graph_item_width
        @graph_item_width ||= width / (labels_x.size + 1)
      end

      def graph_item_height
        @graph_item_height ||= height / labels_y.size
      end

      def color_by_value(value)
        return gradient_colors.first if max_value.zero?

        color_index = (value * (gradient_colors.size - 1) / max_value.to_f).round
        gradient_colors[color_index]
      end
    end
  end
end
