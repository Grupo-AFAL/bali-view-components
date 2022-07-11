# frozen_string_literal: true

module Bali
  module Tags
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
      def tags(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
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
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def tags_with_addons(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
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

      # Tag view as delete
      # ---------------
      # Tags with class `has-addons` on main container and delete in tag view, 
      # this allow us to group a single tag with delete button.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def tag_detele_with_addons(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
          light: light,
          rounded: rounded,
          class: 'has-addons'
        ) do |c|
          c.item(
            text: 'Tag item with text',
            delete: true,
            href: '#'
          )
        end
      end

      # Tag view as delete
      # ---------------
      # Delete tag view, juts specify `delete` to true on each item. Text will be ommited.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def delete_tags(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
          light: light,
          rounded: rounded
        ) do |c|
          c.item(
            text: 'Delete tag view',
            delete: true,
            href: '#'
          )

          c.item(
            color: :black,
            delete: true
          )

          c.item(
            color: :light,
            delete: true
          )

          c.item(
            color: :white,
            delete: true
          )

          c.item(
            color: :primary,
            delete: true
          )

          c.item(
            color: :link,
            delete: true
          )

          c.item(
            color: :info,
            delete: true
          )

          c.item(
            color: :success,
            delete: true
          )

          c.item(
            color: :warning,
            delete: true
          )
          
          c.item(
            color: :danger,
            delete: true
          )
        end
      end

      # Tag view
      # ---------------
      # Link tag view with text.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def link_tag(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
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

      # Tag view
      # ---------------
      # Link tag view with text. All tags must be with `href` and `ìs_delete` option at true.
      # 
      # **The available sizes are:** small, normal, large.
      #
      # **The available colors are:** black, dark, light, white, primary, link, info, success, warning, danger.
      # @param size [Symbol] select [small, normal, large]
      # @param light toggle
      # @param rounded toggle
      def link_with_control_tag(size: :normal, light: false, rounded: false)
        render Tags::Component.new(
          sizes: size,
          light: light,
          rounded: rounded
        ) do |c|
          c.item(
            text: 'Tag item with text',
            href: '#',
            delete: true
          )

          c.item(
            text: 'Tag item with text',
            href: '#',
            delete: true
          )
        end
      end
    end
  end
end