# frozen_string_literal: true

module Bali
  module Link
    class Preview < ApplicationViewComponentPreview
      # Basic link
      # ----------
      def default
        render Bali::Link::Component.new(name: 'Click me!', href: '#')
      end

      # Link with type primary
      # ---------------------
      # This will add the class `button` and `is-primary` to the link.
      # @param type select [primary, success, danger, warning, info, link]
      def primary(type: :prymary)
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: type)
      end

      # Link with size class
      # ------------------
      # This will change the size of the link.
      # @param size select [small, normal, medium, large]
      def size(size: :small)
        render Bali::Link::Component.new(name: 'Small', href: '#', class: "button is-#{size}")
      end

      # Link with icon
      # --------------
      # This will add an icon to the link.
      def with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#') do |c|
          c.icon('books')
        end
      end

      # Link with icon
      # --------------
      # This will add an icon to the link with class button is-primary.
      def button_with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :primary) do |c|
          c.icon('books')
        end
      end

      # Link with just an icon
      # --------------
      # This will add an icon to the link but no text.
      def link_with_just_icon
        render Bali::Link::Component.new(href: '#') do |c|
          c.icon('address-book')
        end
      end

      # Link with `is-active` class
      # --------------
      # This will add the `is-active` class if the `active_path` is the same as the href.
      def is_active
        render Bali::Link::Component.new(name: 'Click me!', href: '#', active_path: '#',
                                         class: 'button')
      end

      # Link with `data-turbo-method` attribute
      # --------------
      # This will add the `data-turbo-method` attribute to the link.
      def data_turbo_method
        render Bali::Link::Component.new(name: 'Click me!', href: '#', method: :post,
                                         class: 'button')
      end
    end
  end
end
