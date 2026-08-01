# frozen_string_literal: true

module Bali
  module Heatmap
    class Component < ApplicationViewComponent
      CELL_CLASSES = "heatmap-cell rounded-sm"
      LABEL_CLASSES = "text-xs text-center truncate text-base-content/70"
      X_LABEL_CLASSES = "#{LABEL_CLASSES} pt-2".freeze
      Y_LABEL_CLASSES = "#{LABEL_CLASSES} pr-3 text-right".freeze

      DEFAULT_COLOR = :primary

      renders_one :x_axis_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: "text-xs font-medium text-base-content/70")
      }

      renders_one :y_axis_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: "text-xs font-medium text-base-content/70")
      }

      renders_one :legend_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.span(content, class: "text-xs font-medium")
      }

      renders_one :hovercard_title, ->(text = nil, &block) {
        content = text || (block ? capture(&block) : nil)
        tag.p(content, class: "font-bold mb-1")
      }

      attr_reader :html_options

      # @param data [Hash] Heatmap data in format { x_label => { y_label => value } }
      # @param color [Symbol] Semantic base colour of the ramp (Bali::Color::NAMES)
      # @param custom_color [String, nil] Hex base colour, for a ramp outside the theme
      # @param cell_size [Integer] Size of each cell in pixels (default: auto-calculated)
      # @param responsive [Boolean] If true, stretches to fill container width
      # rubocop:disable Metrics/ParameterLists
      def initialize(data:, color: DEFAULT_COLOR, custom_color: nil, cell_size: nil,
                     responsive: true, **html_options)
        # rubocop:enable Metrics/ParameterLists
        @data = data
        @custom_color = Bali::Color.hex!(self.class, custom_color)
        @color = @custom_color || Bali::Color.name!(self.class, color || DEFAULT_COLOR)
        @cell_size = cell_size
        @responsive = responsive
        @html_options = prepend_class_name(html_options, component_classes)
      end

      # Public API for template
      def x_labels
        @x_labels ||= @data.keys
      end

      def y_labels
        @y_labels ||= compute_y_labels
      end

      # The ramp is built out of the theme variable, not out of a hex constant, so
      # a heatmap declared `:primary` is the host's primary rather than the
      # indigo this component used to hardcode.
      def gradient_colors
        @gradient_colors ||= Bali::Color.gradient(@color)
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
        "w-full border-separate table-fixed"
      end

      private

      def component_classes
        "heatmap-component w-full"
      end

      # Integer y-keys are treated as a scale, so the range is filled in and rows
      # with no data still get a (zero-valued) row — that is the point for hours of
      # the day. Any other key type is a label, not a scale: `("Fri".."Mon")` is a
      # nonsense range of thousands of strings, and mixing types raises outright, so
      # those keep the keys as given, in first-seen order.
      def compute_y_labels
        keys = @data.values.flat_map(&:keys)
        return [ 0 ] if keys.empty?
        return keys.uniq unless keys.all?(Integer)

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
