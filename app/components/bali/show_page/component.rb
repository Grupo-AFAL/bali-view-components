# frozen_string_literal: true

module Bali
  module ShowPage
    # Everything but `height:` (title, subtitle, breadcrumbs, back, max_width, sidebar_width,
    # context, and the nav, title_tags, body, sidebar and actions slots) lives in
    # PageComponents::Shared.
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      HEIGHTS = %i[content full].freeze

      # @param height [Symbol] `:content` (default) lets the body grow with its content and
      #   the page scroll. `:full` makes the body fill what the header leaves of the nearest
      #   ancestor with a definite height — SplitView's `height: :full`, for a body that is
      #   one panel reaching the bottom of the screen, such as a chat. It is `height: 100%`
      #   and a flex chain, nothing measured, so pair it with
      #   `Bali::AppLayout::Component.new(viewport_locked: true)`: with no bounded ancestor
      #   it fills nothing. Only from `lg` up. An unknown value raises ArgumentError.
      def initialize(height: :content, **options)
        super(**options)
        @height = validated_height(height)
      end

      private

      def full_height? = @height == :full

      # Raises rather than falling back, like SplitView's: `height: :fill` rendering the
      # default in silence sends the reader hunting in the CSS.
      def validated_height(value)
        height = value&.to_sym
        return height if HEIGHTS.include?(height)

        raise ArgumentError,
              "height must be one of #{HEIGHTS.map(&:inspect).join(', ')}, got #{value.inspect}."
      end

      # A flex column does not collapse margins: the header's `mb-4` and the body's `mt-6`
      # measured 40px apart instead of 24. Without it, the body's `mt-6` (or the nav's `mt-4`)
      # is the whole gap, as it already is in normal flow. A utility because `mb-4` is one:
      # a rule in index.css, in `@layer components`, would lose to it.
      def page_header_class
        class_names(super, ("lg:mb-0" if full_height?))
      end

      def page_body_class
        class_names(super, ("show-page-body--full" if full_height?))
      end
    end
  end
end
