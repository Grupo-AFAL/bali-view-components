# frozen_string_literal: true

# Data input formats:
#  Format 1:
#    { "Lun": 0, "Mar": 0, "Mié": 0, "Jue": 0, "Vie": 0, "Sáb": 0, "Dom": 0 }
#    where:
#     - key is x axis label
#     - value is y axis value

#  Format 2:
#    {
#      labels: ["Wed, 12 Jan 2022","Thu, 13 Jan 2022"],
#      datasets: [ { label: "Res", data: [0, 0] }, { label: "Cerdo", data: [0, 0] } ]
#    }
#    where:
#     - labels are x axis labels
#     - label inside data is dataset label
#     - label (dataset label) is optional
#     - values must be the same length as labels

module Bali
  module Chart
    class Component < ApplicationViewComponent
      MAX_LABEL_X_LENGTH = 16

      attr_reader :type, :data, :options, :html_options, :title, :display_percent, :color_picker,
                  :order, :y_axis_ids

      def initialize(
        type: :bar,
        data: {},
        order: [],
        y_axis_ids: [],
        options: { responsive: true, maintainAspectRatio: false },
        **html_options
      )
        @type = Array.wrap(type)
        @data = data
        @options = options
        @order = order
        @y_axis_ids = y_axis_ids

        @title = html_options.delete(:title)
        @display_percent = html_options.delete(:display_percent)

        overwrite_legend_option(@options, html_options.delete(:legend) || false)

        @html_options = html_options
        @color_picker = Bali::Utils::ColorPicker.new
      end

      def labels
        @labels ||= (data[:labels] || data.keys.map(&:to_s))
      end

      def truncated_labels
        @truncated_labels ||= labels.map { |label| label.to_s.truncate(MAX_LABEL_X_LENGTH) }
      end

      def datasets
        @datasets ||= values.map.with_index do |dataset_info, index|
          dataset_info[:type] ||= (type[index] || type.first)
          dataset_info[:order] ||= order[index]
          dataset_info[:yAxisID] ||= y_axis_ids[index]

          Dataset.new(color: dataset_color(dataset_info[:type]), **dataset_info.compact).result
        end
      end

      private

      def values
        @values ||= data[:datasets].deep_dup || [{ label: '', data: data.values }]
      end

      def dataset_color(graph_type)
        return labels.map { |_| color_picker.next_color } if multiple_dataset_colors?(graph_type)

        [color_picker.next_color]
      end

      def multiple_dataset_colors?(graph_type)
        %i[pie doughnut polarArea].include?(graph_type)
      end

      def overwrite_legend_option(opts, legend)
        opts[:plugins] ||= {}
        opts[:plugins][:legend] ||= {}
        opts[:plugins][:legend].merge!(display: legend)
      end
    end
  end
end
