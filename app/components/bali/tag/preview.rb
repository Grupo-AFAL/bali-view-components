# frozen_string_literal: true

module Bali
  module Tag
    class Preview < ApplicationViewComponentPreview
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      def tag(size: :md, color: :neutral, style: nil)
        render Tag::Component.new(
          text: 'Tag item with text',
          color: color,
          size: size,
          style: style
        )
      end

      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      def tag_with_link(size: :md, color: :neutral, style: nil)
        render Tag::Component.new(
          href: '/',
          text: 'Tag item with text',
          color: color,
          size: size,
          style: style
        )
      end
    end
  end
end
