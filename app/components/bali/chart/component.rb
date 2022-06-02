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
      LINE_GRAPH_TENSION = 0.3
  
      attr_reader :data, :type, :id, :title, :legend, :axis, :order,
                  :chart_options, :html_options
  
      def initialize(data:, type: :bar, axis: [], order: [], legend: false, **options)
        @data = data
        @axis = axis
        @order = order
        @legend = legend
        @type = Array.wrap(type)
        @title = options.delete(:title)
        @chart_options = options.delete(:chart_options) || {}
        @html_options = options
        @color_pointer = 0
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
            tension: LINE_GRAPH_TENSION
          }.merge!(datasets_colors(type[index]&.to_sym)).compact
        end
      end

      private

      def datasets_colors(graph_type)
        colors = color_per_dataset?(graph_type)  ? labels.map { |_| picked_color } : [picked_color]
  
        {
          backgroundColor: colors.map { |color| opacify(color) },
          borderColor: colors.map { |color| opacify(color, 7) }
        }
      end

      def color_per_dataset?(graph_type)
        [:pie, :doughnut, :polarArea].include?(graph_type)
      end

      def picked_color
        @color_options ||= colors.keys
  
        picked = colors[@color_options[@color_pointer]]
        @color_pointer >= (@color_options.size - 1) ? @color_pointer = 0 : @color_pointer += 1
  
        picked
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

      def opacify(base_color, opacity = 5)
        "#{base_color}#{(opacity * 255 / 10).to_s(16)}"
      end
    end
  end
end
