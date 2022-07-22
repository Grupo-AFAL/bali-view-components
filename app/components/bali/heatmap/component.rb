# frozen_string_literal: true

module Bali
  module Heatmap
    class Component < ApplicationViewComponent  
      attr_reader :legend_title, :title, :data, :hovercard_title, :x_axis_title, :y_axis_title,
                  :width, :height, :gradient_base_color, :subtitle
  
      def initialize(width: 480, height: 480, data: {}, **options)
        @width = width
        @height = height
        @data = data
        @title = options.delete(:title)
        @subtitle = options.delete(:subtitle)
        @x_axis_title = options.delete(:x_axis_title)
        @y_axis_title = options.delete(:y_axis_title)
        @legend_title = options.delete(:legend_title)
        @hovercard_title = options.delete(:hovercard_title)
        @gradient_base_color = options.delete(:gradient_base_color) || '#008806'
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
  
      def gradient_colors
        @gradient_colors ||= (0..10).map do |opacity|
          opacify(gradient_base_color, opacity)
        end
      end
  
      def color_by_value(value)
        return gradient_colors.first if max_value.zero?
  
        color_index = (value * (gradient_colors.size - 1) / max_value.to_f).round
        gradient_colors[color_index]
      end

      def opacify(base_color, opacity = 5)
        "#{base_color}#{(opacity * 255 / 10).to_s(16)}"
      end
    end
  end
end
