# frozen_string_literal: true

module Bali
  module Progress
    class Preview < ApplicationViewComponentPreview
      # @param value range { min: 0, max: 100, step: 5 }
      # @param color [Symbol] select [~, primary, secondary, accent, neutral, info, success, warning, error]
      # @param show_percentage toggle
      def default(value: 75, color: nil, show_percentage: true)
        render Progress::Component.new(value: value, color: color, show_percentage: show_percentage)
      end

      def all_colors
        render_with_template
      end
    end
  end
end
