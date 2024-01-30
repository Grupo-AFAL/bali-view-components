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
          c.with_item(
            text: 'Tag item with text'
          )

          c.with_item(
            text: 'Tag item with text',
            color: :black
          )

          c.with_item(
            text: 'Tag item with text',
            color: :light
          )

          c.with_item(
            text: 'Tag item with text',
            color: :white
          )

          c.with_item(
            text: 'Tag item with text',
            color: :primary
          )

          c.with_item(
            text: 'Tag item with text',
            color: :link
          )

          c.with_item(
            text: 'Tag item with text',
            color: :info
          )

          c.with_item(
            text: 'Tag item with text',
            color: :success
          )

          c.with_item(
            text: 'Tag item with text',
            color: :warning
          )

          c.with_item(
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
          c.with_item(
            text: 'Tag item with text'
          )

          c.with_item(
            text: 'Tag item with text',
            color: :primary
          )

          c.with_item(
            text: 'Tag item with text',
            color: :link
          )

          c.with_item(
            text: 'Tag item with text',
            color: :info
          )

          c.with_item(
            text: 'Tag item with text',
            color: :success
          )

          c.with_item(
            text: 'Tag item with text',
            color: :warning
          )

          c.with_item(
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
          c.with_item(
            text: 'Tag item with text',
            href: '#'
          )

          c.with_item(
            text: 'Tag item with text',
            href: '#'
          )
        end
      end
    end
  end
end
