# frozen_string_literal: true

module Bali
  module Link
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Link
      # ---------------
      # Basic link with underline style. Uses DaisyUI `link` class with
      # `inline-flex` for proper icon alignment.
      def default
        render Bali::Link::Component.new(name: 'Click me!', href: '#')
      end

      # Button Link
      # ---------------
      # Link styled as a button using DaisyUI btn classes.
      # Use `variant` for color, `style` for appearance, and `size` for dimensions.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error, ghost, link, neutral]
      # @param style [Symbol] select [~, outline, soft]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def button_link(variant: :primary, style: nil, size: :md)
        render Bali::Link::Component.new(name: 'Click me!', href: '#', variant: variant, style: style, size: size)
      end

      # @!endgroup

      # @!group With Icons

      # With Icon
      # ---------------
      # Link with an icon on the left using `icon_name` parameter.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error, ghost, link]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def with_icon(variant: :primary, size: :md)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', icon_name: 'book', variant: variant, size: size
        )
      end

      # With Icon Slot
      # ---------------
      # Link with icon using the `with_icon` slot for more control over icon options.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_icon_slot(variant: :primary)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', variant: variant, size: :lg
        ) do |c|
          c.with_icon('book')
        end
      end

      # Icon Only
      # ---------------
      # Button link with just an icon, no text. Useful for icon buttons.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error, ghost]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      def with_icon_only(variant: :primary, size: :md)
        render Bali::Link::Component.new(
          href: '#', variant: variant, icon_name: 'user', size: size
        )
      end

      # Icon Right
      # ---------------
      # Link with icon on the right side using `with_icon_right` slot.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_icon_right(variant: :primary)
        render Bali::Link::Component.new(
          name: 'Click me!', href: '#', variant: variant
        ) do |c|
          c.with_icon_right('chevron-right')
        end
      end

      # @!endgroup

      # @!group States

      # Active Link
      # ---------------
      # Link with `active` class applied. Can be set explicitly or auto-detected
      # from the current path using `active_path`.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def active_link(variant: :primary)
        render Bali::Link::Component.new(
          name: 'Active Link', href: '#', active_path: '#', variant: variant
        )
      end

      # Disabled Link
      # ---------------
      # Disabled button link. Removes `href` and adds `btn-disabled` class.
      # Only applies disabled styling when `variant` is set.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def disabled(variant: :primary)
        render Bali::Link::Component.new(
          name: 'Disabled',
          href: '/',
          variant: variant,
          disabled: true
        )
      end

      # @!endgroup

      # @!group Special Modes

      # Plain Link
      # ---------------
      # Link without DaisyUI styling, just flex alignment for menu items.
      # Useful in navigation menus or dropdown items.
      def plain
        render Bali::Link::Component.new(
          name: 'Menu Item', href: '#', icon_name: 'home', plain: true
        )
      end

      # With Turbo Method
      # ---------------
      # Link with `data-turbo-method` for non-GET requests (POST, DELETE, etc.).
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_turbo_method(variant: :primary)
        render Bali::Link::Component.new(
          name: 'POST Request', href: '#', method: :post, variant: variant
        )
      end

      # Custom Content
      # ---------------
      # Link with custom HTML content using a block.
      # @param variant [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_custom_content(variant: :primary)
        render_with_template(locals: { variant: variant })
      end

      # @!endgroup

      # @!group Reference

      # All Combinations
      # ---------------
      # Complete visual reference showing all variants, sizes, states, and icon options.
      def all_combinations
        render_with_template
      end

      # @!endgroup
    end
  end
end
