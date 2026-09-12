# frozen_string_literal: true

module Bali
  module Tag
    class Preview < ApplicationViewComponentPreview
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      # @param rounded toggle
      def default(size: :md, color: :neutral, style: nil, rounded: false)
        render Tag::Component.new(
          text: 'Tag item with text',
          color: color,
          size: size,
          style: style,
          rounded: rounded
        )
      end

      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      def with_link(size: :md, color: :neutral, style: nil)
        render Tag::Component.new(
          href: '/lookbook',
          text: 'Clickable Tag',
          color: color,
          size: size,
          style: style
        )
      end

      # Tags support custom hex colors with automatic contrast calculation.
      # @param custom_color text
      def custom_color(custom_color: '#3b82f6')
        render Tag::Component.new(
          text: 'Custom Color',
          custom_color: custom_color
        )
      end

      # The `icon:` keyword draws the glyph before the text at the pill's own
      # font-size, so it fits every badge size — including `xs`, whose pill is
      # only 16px tall. The `with_icon` slot takes options and wins over the
      # keyword when both are given.
      # @param icon text
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [neutral, primary, secondary, accent, ghost, info, success, warning, error]
      # @param style [Symbol] select [~, outline, soft, dash]
      def with_icon(icon: 'check', size: :md, color: :success, style: nil)
        render Bali::Tag::Component.new(
          text: 'Done',
          icon: icon,
          size: size,
          color: color,
          style: style
        )
      end

      # @label Enum map (Tag.for)
      # `Bali::Tag.for(value, map:, i18n_scope:)` is the enum-badge sugar: the
      # value → color/icon map is declared once (in a host helper) instead of
      # once per call site. An unmapped value raises unless `default:` is
      # given. Recipe and the Tag vs Status criterion: docs/guides/enum-badges.md.
      def enum_map
        render_with_template
      end

      # @label All Combinations
      # Shows all tag variants organized by category: colors, sizes, styles,
      # rounded, clickable, custom colors, and a full color x style matrix.
      def all_combinations
        render_with_template
      end

      # @label Long Text
      # A Tag never wraps: daisyUI's `.badge` has a fixed height, so a second
      # line would render outside the pill. These containers squeeze a Tag below
      # the width its text needs — narrow columns, a table cell, a card body.
      def long_text
        render_with_template
      end
    end
  end
end
