# frozen_string_literal: true

module Bali
  module Heatmap
    class Component < ApplicationViewComponent
      CELL_CLASSES = 'heatmap-cell rounded-sm'
      LABEL_CLASSES = 'text-xs text-center truncate text-base-content/70'
      X_LABEL_CLASSES = "#{LABEL_CLASSES} pt-2".freeze
      Y_LABEL_CLASSES = "#{LABEL_CLASSES} pr-3 text-right".freeze

      # DaisyUI color presets using theme variables
      COLOR_PRESETS = {
        primary: '#6366f1', # Will be converted to gradient
        secondary: '#8b5cf6',
        accent: '#f59e0b',
        success: '#22c55e',
        info: '#3b82f6',
        warning: '#f59e0b',
        error: '#ef4444'
      }.freeze

      renders_one :x_axis_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: 'text-xs font-medium text-base-content/70')
      }

      renders_one :y_axis_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: 'text-xs font-medium text-base-content/70')
      }

      renders_one :legend_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: 'text-xs font-medium')
      }

      renders_one :hovercard_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.p(content, class: 'font-bold mb-1')
      }

      attr_reader :html_options

      # @param data [Hash] Heatmap data in format { x_label => { y_label => value } }
      # @param color [String, Symbol] Base color (hex string or DaisyUI preset symbol)
      # @param cell_size [Integer] Size of each cell in pixels (default: auto-calculated)
      # @param responsive [Boolean] If true, stretches to fill container width
      def initialize(data:, color: :primary, cell_size: nil, responsive: true, **html_options)
        @data = data
        @color = resolve_color(color)
        @cell_size = cell_size
        @responsive = responsive
        @html_options = prepend_class_name(html_options, component_classes)
      end

      def resolve_color(color)
        if color.is_a?(Symbol) || COLOR_PRESETS.key?(color.to_sym)
          return COLOR_PRESETS[color.to_sym]
        end

        color
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
        # Always include height for cells to render properly
        "background: #{color_for_value(value)}; min-height: #{cell_size}px; height: #{cell_size}px"
      end

      def cell_size
        @cell_size || 28
      end

      def responsive?
        @responsive
      end

      def table_classes
        'w-full border-separate table-fixed'
      end

      private

      def component_classes
        'heatmap-component w-full'
      end

      def compute_y_labels
        keys = @data.values.flat_map(&:keys)
        return [0] if keys.empty?

        (keys.min..keys.max)
      end

      def all_values
        @all_values ||= @data.values.flat_map(&:values)
      end

      def color_for_value(value)
        return gradient_colors.first if max_value.zero?

        index = (value * (gradient_colors.size - 1) / max_value.to_f).round
        gradient_colors[index]
      end
    end
  end
end
