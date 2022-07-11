# frozen_string_literal: true

module Bali
  module Tag
    class Preview < ApplicationViewComponentPreview
      # Tag view
      # ---------------
      # Basic tag view with text.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def tag(size: :normal, light: false, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          size: size,
          light: light,
          rounded: rounded
        )
      end

      # Tag view
      # ---------------
      # Colored tag view with text.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def tag_color(size: :normal, light: false, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          color: :black,
          size: size,
          light: light,
          rounded: rounded
        )
      end

      # Tag view
      # ---------------
      # Delete tag view with text.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def tag_delete_with_text(size: :normal, light: false, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          delete: true,
          color: :black,
          size: size,
          light: light,
          rounded: rounded
        )
      end

      # Tag view
      # ---------------
      # Delete tag view without text.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def tag_delete_without_text(size: :normal, light: false, rounded: false)
        render Tag::Component.new(
          delete: true,
          color: :black,
          size: size,
          light: light,
          rounded: rounded
        )
      end
    end
  end
end
