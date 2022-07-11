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

      # Tag view
      # ---------------
      # Delete tag view with text.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param color [Symbol] select [black, dark, light, white, primary, link, info, success, warning, danger]
      # @param light toggle
      # @param rounded toggle
      def tag_delete_with_text(size: :normal, color: :light, light: false, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          color: color,
          delete: {
            data: {confirm: 'Are you sure?'}
          },
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
      # @param color [Symbol] select [black, dark, light, white, primary, link, info, success, warning, danger]
      # @param light toggle
      # @param rounded toggle
      def tag_delete_without_text(size: :normal, color: :black, light: false, rounded: false)
        render Tag::Component.new(
          delete: {
            data: {confirm: 'Are you sure?'}
          },
          color: color,
          size: size,
          light: light,
          rounded: rounded
        )
      end
    end
  end
end
