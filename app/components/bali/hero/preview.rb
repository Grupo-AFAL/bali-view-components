# frozen_string_literal: true

module Bali
  module Hero
    class Preview < ApplicationViewComponentPreview
      # @param size [Symbol] select [normal, medium, large]
      # @param color [Symbol] select [white, primary, link, info, success, warning, danger]
      def default(size: nil, color: nil)
        render Hero::Component.new(size: size, color: color) do |c|
          c.title('Title')
          c.subtitle('Title')
        end
      end
    end
  end
end
