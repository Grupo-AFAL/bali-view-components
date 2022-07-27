# frozen_string_literal: true

module Bali
  module Heatmap
    class Preview < ApplicationViewComponentPreview
      # Heatmap
      # -------------------
      # A graph that shows magnitude of a data as color in two dimensions.
      # @param width number
      # @param height number
      def default(width: 480, height: 480)
        data = {
          Dom: { 0 => 0, 1 => 10, 2 => 3 },
          Lun: { 0 => 3, 1 => 1, 2 => 6 },
          Mar: { 0 => 2, 1 => 1, 2 => 4 }
        }
  
        render Bali::Heatmap::Component.new(
          width: width.to_i, height: height.to_i, data: data
        ) do |c|
          c.x_axis_title('Days')
          c.y_axis_title('Hours')
          c.hovercard_title('Clicks by hour of day')
          c.legend_title('Clicks by hour of day')
        end
      end
    end
  end
end
