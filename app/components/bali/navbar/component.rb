# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      BASE_CLASSES = "navbar"
      STICKY_CLASSES = "sticky top-0 z-50"

      # `shadow: false` emits a class instead of skipping one, because the
      # default it turns off is not a class: it is `.navbar { @apply shadow-sm }`
      # in navbar/index.css. The default had to move there so that
      # `.navbar.is-transparent { @apply shadow-none }` — same layer, one
      # compound more specific — finally beats it; as a utility on the element it
      # never did. Nothing declared in @layer components can be undone from the
      # `class:` option, so the off switch has to come from @layer utilities,
      # which outranks it.
      NO_SHADOW_CLASSES = "shadow-none"

      # Bali classes and not Tailwind utilities, for the same reason as the shadow: the
      # preset has to live in the layer where `.navbar.is-transparent` can override it. As
      # utilities on the element they beat the state rule from another layer, and a navbar
      # with `transparency: true` was not transparent — measured on
      # /lookbook/preview/bali/navbar/with_sidebar_burger?transparency=true, with
      # `is-transparent` set the background stayed at `oklch(1 0 0)`.
      #
      # The declarations are in navbar/index.css, in @layer components and ABOVE the
      # `.is-transparent` rule: both are (0,2,0), so order decides.
      #
      # Incidentally, a host that wants to override the preset's color with a utility now
      # wins outright, instead of tying against `bg-base-100` and depending on sheet order.
      COLORS = {
        base: "navbar-base",
        primary: "navbar-primary",
        secondary: "navbar-secondary",
        accent: "navbar-accent",
        neutral: "navbar-neutral"
      }.freeze

      # Brand slot - accepts content block or name parameter
      renders_one :brand

      renders_many :burgers, Burger::Component
      renders_many :menus, Menu::Component

      # @param sticky [Boolean] Make navbar sticky at top (default: true)
      # @param transparency [Boolean] Enable transparent mode
      # @param fullscreen [Boolean] Full-width navbar without max-width constraint
      # @param color [Symbol, nil] Background color preset (:base, :primary, :secondary, :accent,
      #   :neutral). Pass nil to skip color classes and use your own via the class: option.
      # @param shadow [Boolean] Draw the drop shadow under the bar (default: true).
      #   Pass false where the bar already separates itself some other way — an app
      #   shell whose navbar carries a bottom border that continues the sidebar's
      #   gets two dividers otherwise.
      def initialize(sticky: true, transparency: false, fullscreen: false, color: :base,
                     shadow: true, **options)
        @sticky = sticky
        @transparency = transparency.present?
        @fullscreen = fullscreen.present?
        @color = color&.to_sym
        @shadow = shadow
        @container_class = options.delete(:container_class)

        @options = prepend_controller(options, "navbar")
        @options = prepend_class_name(options, navbar_classes)
        @options = prepend_data_attribute(options, "navbar-allow-transparency-value", @transparency)
        @options = prepend_data_attribute(options, "navbar-throttle-interval-value", 100)
      end

      # Classes for the inner container wrapper
      # - Fullscreen: edge-to-edge with padding, no width constraint
      # - Non-fullscreen: centered with max-width constraint (max-w-7xl = 1280px)
      def container_classes
        base = "flex items-center w-full relative px-4"
        if @fullscreen
          class_names(base, @container_class)
        else
          class_names(base, "max-w-7xl mx-auto", @container_class)
        end
      end

      private

      attr_reader :transparency, :fullscreen, :sticky, :options

      def color_classes
        COLORS.fetch(@color, nil)
      end

      # `@options[:class]` is deliberately absent: `prepend_class_name` appends
      # whatever the caller passed after this string, so naming it here printed
      # every host class twice — measured on the AppLayout preview, the
      # `min-h-0 bali-chrome-height border-b border-base-300` it passes came out
      # in the attribute two times over.
      def navbar_classes
        class_names(
          BASE_CLASSES,
          color_classes,
          @sticky && STICKY_CLASSES,
          !@shadow && NO_SHADOW_CLASSES
        )
      end
    end
  end
end
