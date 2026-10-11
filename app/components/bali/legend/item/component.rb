# frozen_string_literal: true

module Bali
  module Legend
    module Item
      class Component < ApplicationViewComponent
        BASE_CLASSES = "legend-item"

        # The icon is ink on the page, where the colour itself fails the 3:1 of a graphic:
        # `text-warning` read 1.69:1 on `afal`. The dot keeps the colour itself, because it has
        # to match the marks it explains, which the host paints with that same value.
        # `neutral` is base-content: a dark theme's neutral is a fill, not ink.
        ICON_COLORS = {
          neutral: "text-base-content",
          primary: "text-soft-primary",
          secondary: "text-soft-secondary",
          accent: "text-soft-accent",
          info: "text-soft-info",
          success: "text-soft-success",
          warning: "text-soft-warning",
          error: "text-soft-error",
          ghost: "text-base-content/60"
        }.freeze

        # `:ghost`, no colour of its own, is the one name that paints apart from `:neutral`: muted,
        # like the rows of a state that has none (a draft). The dot at 55% read 3.49:1 on `afal`
        # and 5.06 on `afal-dark`; the icon at /60, 4.04 and 5.82 (WCAG 1.4.11: 3).
        GHOST_DOT_ALPHA = 55

        # @param label [String] What the colour means
        # @param color [Symbol, nil] Semantic colour (Bali::Color::NAMES). `:ghost` paints muted:
        #   the dot at 55% of base-content and the icon at /60, where `:neutral` is base-content.
        # @param custom_color [String, nil] Hex colour; wins over `color:`
        # @param icon [String, nil] Icon name (Bali::Icon pipeline), drawn after the dot
        # @param description [String, nil] Longer explanation, behind a Bali::HelpTip
        # @param options [Hash] HTML attributes for the `<li>`
        def initialize(label:, color: nil, custom_color: nil, icon: nil, description: nil, **options)
          @label = label
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          @color = @custom_color ? nil : Bali::Color.name!(self.class, color)
          @icon = icon
          @description = description
          @options = prepend_class_name(options, BASE_CLASSES)

          return if @custom_color || @color

          raise ArgumentError, "#{self.class}: an entry needs a `color:` or a `custom_color:`."
        end

        private

        attr_reader :label, :icon, :description, :options

        def marker_color
          return Bali::Color.with_alpha(@color, GHOST_DOT_ALPHA) if @color == Bali::Color::GHOST

          Bali::Color.css(@custom_color || @color)
        end

        def icon_options
          return { style: "color: #{Bali::Color.soft(@custom_color)}" } if @custom_color

          { class: ICON_COLORS.fetch(@color) }
        end
      end
    end
  end
end
