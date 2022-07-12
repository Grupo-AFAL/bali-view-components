# frozen_string_literal: true

module Bali
  module Tags
    class Preview < ApplicationViewComponentPreview
      # Tag view
      # ---------------
      # Basic tag view with text.
      #
      # @param size [Symbol] select [normal, medium, large]
      # @param light toggle
      # @param rounded toggle
      def tags(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          size: size,
          light: light,
          rounded: rounded
        ) do |c|
          c.item(
            text: 'Tag item with text'
          )

          c.item(
            text: 'Tag item with text',
            color: :black
          )

          c.item(
            text: 'Tag item with text',
            color: :light
          )

          c.item(
            text: 'Tag item with text',
            color: :white
          )

          c.item(
            text: 'Tag item with text',
            color: :primary
          )

          c.item(
            text: 'Tag item with text',
            color: :link
          )

          c.item(
            text: 'Tag item with text',
            color: :info
          )

          c.item(
            text: 'Tag item with text',
            color: :success
          )

          c.item(
            text: 'Tag item with text',
            color: :warning
          )

          c.item(
            text: 'Tag item with text',
            color: :danger
          )
        end
      end

      # Tag view
      # ---------------
      # Tags with class `has-addons` on main container,
      # this allow us to group all tags side by side.
      #
      # @param size [Symbol] select [normal, medium, large]
      # @param light toggle
      # @param rounded toggle
      def tags_with_addons(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          size: size,
          light: light,
          rounded: rounded,
          class: 'has-addons'
        ) do |c|
          c.item(
            text: 'Tag item with text'
          )

          c.item(
            text: 'Tag item with text',
            color: :primary
          )

          c.item(
            text: 'Tag item with text',
            color: :link
          )

          c.item(
            text: 'Tag item with text',
            color: :info
          )

          c.item(
            text: 'Tag item with text',
            color: :success
          )

          c.item(
            text: 'Tag item with text',
            color: :warning
          )

          c.item(
            text: 'Tag item with text',
            color: :danger
          )
        end
      end

      # Tag view
      # ---------------
      # Link tag view with text.
      #
      # @param size [Symbol] select [normal, medium, large]
      # @param light toggle
      # @param rounded toggle
      def link_tag(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          size: size,
          light: light,
          rounded: rounded
        ) do |c|
          c.item(
            text: 'Tag item with text',
            href: '#'
          )

          c.item(
            text: 'Tag item with text',
            href: '#'
          )
        end
      end
    end
  end
end
