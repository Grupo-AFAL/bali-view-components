# frozen_string_literal: true

module Bali
  module Progress
    class Preview < ApplicationViewComponentPreview
      # @param value [Integer]
      # @param display_percentage toggle
      def default(value: 30, display_percentage: true)
        render Progress::Component.new(value: value, display_percentage: display_percentage)
      end
    end
  end
end
