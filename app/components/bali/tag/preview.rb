# frozen_string_literal: true

module Bali
  module Tag
    class Preview < ApplicationViewComponentPreview
      # Tag view
      # ---------------
      # Basic tag view with text.
      #
      # @param size [Symbol] select [normal, medium, large]
      # @param color [Symbol] select [black, dark, light, white, primary, link, info, success, warning, danger]
      # @param light toggle
      # @param rounded toggle
      def tag(size: :normal, color: :light, light: false, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          color: color,
          size: size,
          light: light,
          rounded: rounded
        )
      end

      # Tag with Link
      # ---------------
      # Basic tag view with text.
      #
      # @param size [Symbol] select [normal, medium, large]
      # @param color [Symbol] select [black, dark, light, white, primary, link, info, success, warning, danger]
      # @param light toggle
      # @param rounded toggle
      def tag_with_link(size: :normal, color: :light, light: false, rounded: false)
        render Tag::Component.new(
          href: '/',
          text: 'Tag item with text',
          color: color,
          size: size,
          light: light,
          rounded: rounded
        )
      end
    end
  end
end
