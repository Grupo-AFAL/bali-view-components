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
            delete: {
              data: {confirm: 'Are you sure?'}
            },
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
        confirm = {
          data: {confirm: 'Are you sure?'}
        }
        render Tags::Component.new(
          sizes: size,
          light: light,
          rounded: rounded
        ) do |c|
          c.item(
            text: 'Delete tag view',
            delete: confirm
          )

          c.item(
            color: :black,
            delete: confirm
          )

          c.item(
            color: :light,
            delete: confirm
          )

          c.item(
            color: :white,
            delete: confirm
          )

          c.item(
            color: :primary,
            delete: confirm
          )

          c.item(
            color: :link,
            delete: confirm
          )

          c.item(
            color: :info,
            delete: confirm
          )

          c.item(
            color: :success,
            delete: confirm
          )

          c.item(
            color: :warning,
            delete: confirm
          )
          
          c.item(
            color: :danger,
            delete: confirm
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
        confirm = {
          data: {confirm: 'Are you sure?'}
        }
        render Tags::Component.new(
          sizes: size,
          light: light,
          rounded: rounded
        ) do |c|
          c.item(
            text: 'Tag item with text',
            href: '#',
            delete: confirm
          )

          c.item(
            text: 'Tag item with text',
            href: '#',
            delete: confirm
          )
        end
      end
    end
  end
end
