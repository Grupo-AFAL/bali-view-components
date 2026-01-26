# frozen_string_literal: true

module Bali
  module Tag
    class Preview < ApplicationViewComponentPreview
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      # @param rounded toggle
      def default(size: :md, color: :neutral, style: nil, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          color: color,
          size: size,
          style: style,
          rounded: rounded
        )
      end

      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      def with_link(size: :md, color: :neutral, style: nil)
        render Tag::Component.new(
          href: '/lookbook',
          text: 'Clickable Tag',
          color: color,
          size: size,
          style: style
        )
      end

      # Tags support custom hex colors with automatic contrast calculation.
      # @param custom_color text
      def custom_color(custom_color: '#3b82f6')
        render Tag::Component.new(
          text: 'Custom Color',
          custom_color: custom_color
        )
      end
    end
  end
end
