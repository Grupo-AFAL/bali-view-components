# frozen_string_literal: true

module Bali
  module Heatmap
    class Preview < ApplicationViewComponentPreview
      def default(title: '', width: 480, height: 480)
        data = {
          Dom: { 0 => 0, 1 => 10, 2 => 3 },
          Lun: { 0 => 3, 1 => 1, 2 => 6 },
          Mar: { 0 => 2, 1 => 1, 2 => 4 }
        }
  
        render Bali::Heatmap::Component.new(
          title: title, width: width.to_i, height: height.to_i, data: data
        )
      end
    end
  end
end
