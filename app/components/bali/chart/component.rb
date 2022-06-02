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
#     - label is dataset label
#     - label (dataset label) is optional
#     - values must be the same length as labels

module Bali
  module Chart
    class Component < ApplicationViewComponent
      MAX_LABEL_X_LENGTH = 16
  
      attr_reader :data, :type, :id, :title, :legend, :axis, :order,
                  :chart_options, :html_options
  
      def initialize(data:, id:, type: :bar, title: nil, **options)
        @id = id
        @title = title
        @data = data
        @type = Array.wrap(type)
        @chart_options = options.delete(:chart_options) || {}
        @axis = options.delete(:axis) || []
        @order = options.delete(:order) || []
        @legend = options.delete(:legend) || false
        @class = options.delete(:class)
        @html_options = options
        @color_pointer = 0
      end
  
      def classes
        class_names('chart', @class)
      end
  
      def chart_data
        { labels: labels, datasets: datasets }
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
        values = data[:data] || [{ label: '', values: data.values }]
  
        values.map.with_index do |value, index|
          {
            label: value[:label],
            data: value[:values],
            borderWidth: 2,
            yAxisID: "y_#{axis[index] || 1}",
            type: type[index],
            order: order[index] || 1,
            tension: dataset_tension(type[index]&.to_sym)
          }.merge!(dataset_colors(type[index]&.to_sym)).compact
        end
      end
  
      # Google charts colors samples
      def colors
        @colors ||= {
          blue: '#3366CC',
          red: '#DC3912',
          yellow: '#FF9900',
          green: '#109618',
          purple: '#990099',
          pink: '#DD4477',
          light_green: '#66AA00',
          dark_yellow: '#E67300',
          olive: '#AAAA11',
          turquoise: '#22AA99'
        }
      end
  
      def picked_color
        @color_options ||= colors.keys
  
        picked = colors[@color_options[@color_pointer]]
        @color_pointer >= (@color_options.size - 1) ? @color_pointer = 0 : @color_pointer += 1
  
        picked
      end
  
      def dataset_colors(graph_type)
        colors = [:pie, :doughnut, :polarArea].include?(graph_type)  ? labels.map { |_| picked_color } : [picked_color]
  
        {
          backgroundColor: colors.map { |color| opacify(color) },
          borderColor: colors.map { |color| opacify(color, 7) }
        }
      end

      private

      def dataset_tension(graph_type)
        return unless graph_type == :line
  
        0.3
      end

      def opacify(base_color, opacity = 5)
        "#{base_color}#{(opacity * 255 / 10).to_s(16)}"
      end
    end
  end
end
