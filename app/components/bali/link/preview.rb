# frozen_string_literal: true

module Bali
  module Link
    class Preview < ApplicationViewComponentPreview
      # Basic link
      # --------------
      # This will return a basic link with the name and href.
      def default
        render Bali::Link::Component.new(name: 'Click me!', href: '#')
      end

      # Basic usage
      # -------------
      # This will add the class `button`, `is-primary` and the size to the link.
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def basic(type: :primary, size: :normal)
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: type,
                                         class: "is-#{size}")
      end

      # Link with icon
      # --------------
      # This will add an icon to the left of the link name
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def with_icon(type: :primary, size: :normal)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', icon_name: 'books', type: type, class: "is-#{size}"
        )
      end

      # Link with icon
      # --------------
      # This will add an icon to the link and pass additional options
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def with_icon_customized(type: :primary, size: :large)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', type: type, class: "is-#{size}"
        ) do |c|
          c.icon('books', class: "is-#{size}")
        end
      end

      # Link with just an icon
      # --------------
      # This will add an icon to the link but no text.
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def link_with_just_icon(type: :primary, size: :normal)
        render Bali::Link::Component.new(
          href: '#', type: type, icon_name: 'address-book', class: "is-#{size}"
        )
      end

      # Link with icon in the right side
      # --------------
      # This will add an icon to the right of the link name
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def with_icon_in_right_side(type: :primary, size: :normal)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', type: type, class: "is-#{size}"
        ) do |c|
          c.icon_right('address-book')
        end
      end

      # Link with `is-active` class
      # --------------
      # This will add the `is-active` class if the `active_path` is the same as the href.
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def is_active(type: :primary, size: :normal)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', active_path: '#', type: type, class: "is-#{size}"
        )
      end

      # Link with `data-turbo-method` attribute
      # --------------
      # This will add the `data-turbo-method` attribute to the link.
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def data_turbo_method(type: :primary, size: :normal)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', method: :post, type: type, class: "is-#{size}"
        )
      end

      # Link with custom content
      # --------------
      # This will add custom content to the link.
      # @param type select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def custom_content(type: :primary, size: :normal)
        render Bali::Link::Component.new(href: '#', type: type, class: "is-#{size}") do |c|
          c.tag.p('custom content')
        end
      end
    end
  end
end
