# frozen_string_literal: true

module Bali
  module BooleanIcon
    class Preview < ApplicationViewComponentPreview

      # @param value [Boolean] toggle
      def default(value: true)
        render Bali::BooleanIcon::Component.new(value: value)
      end
    end
  end
end
