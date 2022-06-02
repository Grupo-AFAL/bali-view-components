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
#      data: [ { label: "Res", values: [0, 0] }, { label: "Cerdo", values: [0, 0] } ]
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

      attr_reader :data, :type, :id, :title, :legend, :axis, :order,
                  :chart_options, :html_options, :color_picker

      def initialize(data:, type: :bar, axis: [], order: [], legend: false, **options)
        @data = data
        @axis = axis
        @order = order
        @legend = legend
        @type = Array.wrap(type)
        @title = options.delete(:title)
        @chart_options = options.delete(:chart_options) || {}
        @html_options = options
        @color_picker = ColorPicker.new
      end

      def options
        if chart_options.dig(:plugins, :legend, :display).blank?
          chart_options.merge!(plugins: { legend: { display: legend } })
        end

        chart_options.merge!(responsive: true, maintainAspectRatio: false)
      end

      def labels
        return @labels if defined? @labels

        @labels = (data[:labels] || data.keys.map(&:to_s))
        @labels.map { |label| label.to_s.truncate(MAX_LABEL_X_LENGTH) }
      end

      def datasets
        values.map.with_index do |dataset_info, index|
          Dataset.new(
            type[index],
            dataset_info[:values],
            dataset_info[:label],
            order[index] || 1,
            "y_#{axis[index] || 1}",
            dataset_colors(type[index])
          ).result
        end
      end

      private

      def values
        @values ||= data[:data] || [{ label: '', values: data.values }]
      end

      def dataset_colors(graph_type)
        return labels.map { |_| color_picker.next_color } if color_per_label?(graph_type)

        [color_picker.next_color]
      end

      def color_per_label?(graph_type)
        %i[pie doughnut polarArea].include?(graph_type)
      end
    end
  end
end
