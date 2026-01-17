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
    class Component < ApplicationViewComponent
      MAX_LABEL_LENGTH = 16
      MULTI_COLOR_TYPES = %i[pie doughnut polarArea].freeze
      DEFAULT_OPTIONS = { responsive: true, maintainAspectRatio: false }.freeze

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
        **html_options
      )
        # rubocop:enable Metrics/ParameterLists
        @types = Array.wrap(type)
        @data = data
        @title = title
        @display_percent = display_percent
        @order = order
        @y_axis_ids = y_axis_ids
        @options = build_options(options, legend)
        @html_options = html_options
        @color_picker = Bali::Utils::ColorPicker.new
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

      def container_classes
        class_names('chart-container h-[250px]', @html_options[:class])
      end

      def container_options
        @html_options.except(:class)
      end

      private

      def build_options(custom_options, legend)
        DEFAULT_OPTIONS
          .merge(custom_options)
          .tap { |opts| configure_legend(opts, legend) }
      end

      def configure_legend(opts, display)
        opts[:plugins] ||= {}
        opts[:plugins][:legend] ||= {}
        opts[:plugins][:legend][:display] = display
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

        Dataset.new(
          color: colors_for_type(info[:type]),
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
  end
end
