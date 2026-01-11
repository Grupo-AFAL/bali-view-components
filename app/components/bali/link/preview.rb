# frozen_string_literal: true

module Bali
  module Link
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Link
      # --------------
      # Basic link with underline style
      def default
        render Bali::Link::Component.new(name: 'Click me!', href: '#')
      end

      # Button Link
      # -------------
      # Link styled as a button using DaisyUI btn classes
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error, ghost, link, neutral]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def button_link(type: :primary, size: :md)
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: type, size: size)
      end

      # @!endgroup

      # @!group With Icons

      # With Icon
      # --------------
      # Link with an icon on the left
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error, ghost, link]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def with_icon(type: :primary, size: :md)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', icon_name: 'books', type: type, size: size
        )
      end

      # With Customized Icon
      # --------------
      # Link with icon using the slot for more control
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_icon_customized(type: :primary)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', type: type, size: :lg
        ) do |c|
          c.with_icon('books')
        end
      end

      # Icon Only
      # --------------
      # Link with just an icon, no text
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error, ghost]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def icon_only(type: :primary, size: :md)
        render Bali::Link::Component.new(
          href: '#', type: type, icon_name: 'address-book', size: size
        )
      end

      # Icon Right
      # --------------
      # Link with icon on the right side
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_icon_right(type: :primary)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', type: type
        ) do |c|
          c.with_icon_right('address-book')
        end
      end

      # @!endgroup

      # @!group States

      # Active Link
      # --------------
      # Link with active class when path matches
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def active_link(type: :primary)
        render Bali::Link::Component.new(
          name: 'Active Link', href: '#', active_path: '#', type: type
        )
      end

      # Disabled Link
      # --------------
      # Disabled button link (no href, visually disabled)
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def disabled(type: :primary)
        render Bali::Link::Component.new(
          name: 'Disabled',
          href: '/',
          type: type,
          disabled: true
        )
      end

      # @!endgroup

      # @!group Custom

      # With Turbo Method
      # --------------
      # Link with data-turbo-method for non-GET requests
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def turbo_method(type: :primary)
        render Bali::Link::Component.new(
          name: 'POST Request', href: '#', method: :post, type: type
        )
      end

      # Custom Content
      # --------------
      # Link with custom HTML content
      # @param type [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def custom_content(type: :primary)
        render Bali::Link::Component.new(href: '#', type: type) do |c|
          c.tag.span('Custom ', class: 'font-bold') + c.tag.span('Content')
        end
      end

      # @!endgroup
    end
  end
end
