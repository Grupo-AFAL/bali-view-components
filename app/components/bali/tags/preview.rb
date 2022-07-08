# frozen_string_literal: true

module Bali
  module Tags
    class Preview < ApplicationViewComponentPreview
      # Tag view
      # ---------------
      # Basic tag view with text.
      # 
      # **Available sizes:** small, normal, large.
      #
      # **Available colors:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light_color toggle
      # @param rounded toggle
      def default(size: :normal, light_color: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
          all_light: light_color,
          all_rounded: rounded
        ) do |c|
          c.tag_item(
            text: 'Tag item with text'
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :black
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :light
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :white
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :primary
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :link
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :info
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :success
          )

          c.tag_item(
            text: 'Tag item with text',
            color: :warning
          )
          
          c.tag_item(
            text: 'Tag item with text',
            color: :danger
          )
        end
      end
    end
  end
end
