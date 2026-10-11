# frozen_string_literal: true

module Bali
  module Legend
    module Item
      class Component < ApplicationViewComponent
        BASE_CLASSES = "legend-item"

        MARKERS = %i[dot swatch].freeze

        # The icon is ink on the page, where the colour itself fails the 3:1 of a graphic:
        # `text-warning` read 1.69:1 on `afal`. The marker keeps the colour itself, because it
        # has to match the marks it explains, which the host paints with that same value.
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
          ghost: "text-base-content"
        }.freeze

        SWATCH_FILL = 20
        SWATCH_BORDER = 40

        # @param label [String] What the colour means
        # @param color [Symbol, nil] Semantic colour (Bali::Color::NAMES)
        # @param custom_color [String, nil] Hex colour; wins over `color:`
        # @param icon [String, nil] Icon name (Bali::Icon pipeline), drawn after the marker
        # @param marker [:dot, :swatch] A solid dot, or a tinted square for a colour the host
        #   paints as a tint (a row, a cell)
        # @param description [String, nil] Longer explanation, behind a Bali::HelpTip
        # @param options [Hash] HTML attributes for the `<li>`
        # rubocop:disable Metrics/ParameterLists
        def initialize(label:, color: nil, custom_color: nil, icon: nil, marker: :dot,
                       description: nil, **options)
          # rubocop:enable Metrics/ParameterLists
          @label = label
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          @color = @custom_color ? nil : Bali::Color.name!(self.class, color)
          @icon = icon
          @marker = validated_marker(marker)
          @description = description
          @options = prepend_class_name(options, BASE_CLASSES)

          return if @custom_color || @color

          raise ArgumentError, "#{self.class}: an entry needs a `color:` or a `custom_color:`."
        end

        private

        attr_reader :label, :icon, :description, :options

        def validated_marker(value)
          key = value.to_sym
          return key if MARKERS.include?(key)

          raise ArgumentError,
                "#{self.class}: unknown marker #{key.inspect}. Valid: #{MARKERS.map(&:inspect).join(', ')}."
        end

        def marker_classes
          "legend-item__marker legend-item__marker--#{@marker}"
        end

        def marker_style
          value = @custom_color || @color
          return "background-color: #{Bali::Color.css(value)}" if @marker == :dot

          "background-color: #{Bali::Color.with_alpha(value, SWATCH_FILL)}; " \
            "border-color: #{Bali::Color.with_alpha(value, SWATCH_BORDER)}"
        end

        def icon_options
          return { style: "color: #{Bali::Color.soft(@custom_color)}" } if @custom_color

          { class: ICON_COLORS.fetch(@color) }
        end
      end
    end
  end
end
