# frozen_string_literal: true

# Data input formats:
#   Format 1 (simple hash):
#     { "Mon" => 10, "Tue" => 20, "Wed" => 30 }
#     where: key is x-axis label, value is y-axis value
#
#   Format 2 (multi-series):
#     {
#       labels: ["Wed, 12 Jan 2022", "Thu, 13 Jan 2022"],
#       datasets: [{ label: "Beef", data: [10, 5] }, { label: "Pork", data: [20, 10] }]
#     }
#     where: labels are x-axis labels, each dataset has its own label and data array

module Bali
  module Chart
    # rubocop:disable Metrics/ClassLength
    class Component < ApplicationViewComponent
      MAX_LABEL_LENGTH = 16
      MULTI_COLOR_TYPES = %i[pie doughnut polarArea].freeze
      BAR_TYPES = %i[bar].freeze

      # System font stack matching DaisyUI/Tailwind
      FONT_FAMILY = 'ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji"'

      DEFAULT_OPTIONS = {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 800,
          easing: 'easeOutQuart'
        }
      }.freeze

      # Card style variants
      CARD_STYLES = {
        default: 'card bg-base-100 shadow-sm',
        bordered: 'card bg-base-100 card-border',
        compact: 'card bg-base-100 card-compact shadow-sm',
        none: '' # No card wrapper
      }.freeze

      # Chart height presets
      HEIGHTS = {
        sm: 'h-[180px]',
        md: 'h-[250px]',
        lg: 'h-[350px]',
        xl: 'h-[450px]'
      }.freeze

      attr_reader :title

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        type: :bar,
        data: {},
        title: nil,
        legend: false,
        display_percent: false,
        order: [],
        y_axis_ids: [],
        options: {},
        card_style: :default,
        height: :md,
        use_theme_colors: true,
        **html_options
      )
        # rubocop:enable Metrics/ParameterLists
        @types = Array.wrap(type)
        @data = data
        @title = title
        @display_percent = display_percent
        @order = order
        @y_axis_ids = y_axis_ids
        @card_style = card_style.to_sym
        @height = height.to_sym
        @use_theme_colors = use_theme_colors
        @options = build_options(options, legend)
        @html_options = html_options
        @color_picker = Bali::Utils::ColorPicker.new(use_theme_colors: use_theme_colors)
      end

      def chart_type
        @types.first
      end

      def chart_data_json
        { labels: truncated_labels, datasets: datasets }.to_json
      end

      def labels_json
        labels.to_json
      end

      def options_json
        @options.to_json
      end

      def display_percent?
        @display_percent
      end

      def card_classes
        CARD_STYLES[@card_style]
      end

      def render_card?
        @card_style != :none
      end

      def container_classes
        class_names(
          'chart-container',
          HEIGHTS[@height] || HEIGHTS[:md],
          @html_options[:class]
        )
      end

      def container_options
        @html_options.except(:class)
      end

      def use_theme_colors?
        @use_theme_colors
      end

      private

      def build_options(custom_options, legend)
        base_opts = DEFAULT_OPTIONS.deep_dup
        configure_legend(base_opts, legend)
        configure_theme_styling(base_opts) if @use_theme_colors

        base_opts.deep_merge(custom_options)
      end

      def configure_legend(opts, display)
        opts[:plugins] ||= {}
        opts[:plugins][:legend] ||= {}
        opts[:plugins][:legend][:display] = display
        opts[:plugins][:legend][:labels] ||= {}
        # Use theme-aware text color for legend
        opts[:plugins][:legend][:labels][:useThemeColors] = @use_theme_colors
      end

      def configure_theme_styling(opts)
        configure_scales_styling(opts)
        configure_plugins_styling(opts)
      end

      def configure_scales_styling(opts)
        opts[:scales] ||= {}

        %w[x y].each do |axis|
          configure_axis_styling(opts[:scales], axis)
        end
      end

      def configure_axis_styling(scales, axis)
        scales[axis] ||= {}
        axis_config = scales[axis]

        # Grid: cleaner, more subtle - only show y-axis grid
        axis_config[:grid] = { useThemeColors: true, drawBorder: false, display: (axis == 'y') }

        # Ticks with proper font
        axis_config[:ticks] = { useThemeColors: true, font: { family: FONT_FAMILY, size: 12 } }

        # Hide axis border
        axis_config[:border] = { display: false }
      end

      def configure_plugins_styling(opts)
        opts[:plugins] ||= {}

        # Tooltip
        opts[:plugins][:tooltip] ||= {}
        opts[:plugins][:tooltip][:useThemeColors] = true

        # Legend font
        opts[:plugins][:legend] ||= {}
        opts[:plugins][:legend][:labels] ||= {}
        opts[:plugins][:legend][:labels][:font] = { family: FONT_FAMILY, size: 12, weight: '500' }
      end

      def labels
        @labels ||= extract_labels
      end

      def extract_labels
        if @data.key?(:labels) || (@data.keys.size == 1 && @data.key?(:datasets))
          Array.wrap(@data[:labels])
        else
          @data.keys.map(&:to_s)
        end
      end

      def truncated_labels
        @truncated_labels ||= labels.map { |label| label.to_s.truncate(MAX_LABEL_LENGTH) }
      end

      def datasets
        @datasets ||= build_datasets
      end

      def build_datasets
        raw_datasets = @data[:datasets]&.deep_dup || [{ label: '', data: @data.values }]

        raw_datasets.map.with_index do |dataset_info, index|
          build_dataset(dataset_info, index)
        end
      end

      def build_dataset(info, index)
        info[:type] ||= @types[index] || @types.first
        info[:order] ||= @order[index]
        info[:yAxisID] ||= @y_axis_ids[index]

        # Add rounded corners for bar charts
        dataset_type = info[:type]&.to_sym
        is_bar = BAR_TYPES.include?(dataset_type)

        Dataset.new(
          color: colors_for_type(info[:type]),
          rounded: is_bar,
          **info.compact
        ).to_h
      end

      def colors_for_type(graph_type)
        if MULTI_COLOR_TYPES.include?(graph_type&.to_sym)
          labels.map { @color_picker.next_color }
        else
          [@color_picker.next_color]
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
