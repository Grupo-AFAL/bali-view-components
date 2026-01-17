# frozen_string_literal: true

module Bali
  module Heatmap
    class Component < ApplicationViewComponent
      CELL_CLASSES = 'heatmap-cell block'
      LABEL_CLASSES = 'text-[0.625rem] text-center truncate'
      X_LABEL_CLASSES = "#{LABEL_CLASSES} border-t border-base-300 pt-3 -rotate-45".freeze
      Y_LABEL_CLASSES = "#{LABEL_CLASSES} border-r border-base-300 pr-4 align-middle".freeze

      MIN_DIMENSION = 100
      MAX_DIMENSION = 2000

      renders_one :x_axis_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: 'text-xs font-bold')
      }

      renders_one :y_axis_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: 'text-xs font-bold')
      }

      renders_one :legend_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: 'font-bold')
      }

      renders_one :hovercard_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.p(content, class: 'font-bold mb-1')
      }

      attr_reader :html_options

      def initialize(data:, width: 480, height: 480, color: '#008806', **html_options)
        @data = data
        @width = width.to_i.clamp(MIN_DIMENSION, MAX_DIMENSION)
        @height = height.to_i.clamp(MIN_DIMENSION, MAX_DIMENSION)
        @color = color
        @html_options = prepend_class_name(html_options, component_classes)
      end

      # Public API for template
      def x_labels
        @x_labels ||= @data.keys
      end

      def y_labels
        @y_labels ||= compute_y_labels
      end

      def gradient_colors
        @gradient_colors ||= Bali::Utils::ColorPicker.gradient(@color)
      end

      def max_value
        @max_value ||= all_values.max || 0
      end

      def value_at(x_label, y_label)
        @data.dig(x_label, y_label) || 0
      end

      def cell_style(value)
        "width: #{cell_width}px; height: #{cell_height}px; background: #{color_for_value(value)}"
      end

      def legend_segment_style(color)
        "background: #{color}; width: #{@width / gradient_colors.size}px"
      end

      private

      def component_classes
        'heatmap-component overflow-x-auto max-w-full'
      end

      def compute_y_labels
        keys = @data.values.flat_map(&:keys)
        return [0] if keys.empty?

        (keys.min..keys.max)
      end

      def all_values
        @all_values ||= @data.values.flat_map(&:values)
      end

      def cell_width
        @cell_width ||= @width / (x_labels.size + 1)
      end

      def cell_height
        @cell_height ||= @height / y_labels.size
      end

      def color_for_value(value)
        return gradient_colors.first if max_value.zero?

        index = (value * (gradient_colors.size - 1) / max_value.to_f).round
        gradient_colors[index]
      end
    end
  end
end
