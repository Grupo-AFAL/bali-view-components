# frozen_string_literal: true

module Bali
  module Progress
    class Preview < ApplicationViewComponentPreview
      # @param value [Integer]
      # @param percentage toggle
      def default(value: 75, percentage: true)
        render Progress::Component.new(value: value, percentage: percentage)
      end

      # @param color_code select ['hsl(196, 82%, 78%)', '#52BE80', 'rgb(205, 92, 92)']
      def with_custom_color(color_code: 'hsl(196, 82%, 78%)')
        render Progress::Component.new(color_code: color_code)
      end
    end
  end
end
