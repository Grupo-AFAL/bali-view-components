# frozen_string_literal: true

module Bali
  module Timeline
    module Header
      # Timeline header component for section dividers within a timeline.
      #
      # Displays a badge centered in the timeline to mark sections or milestones.
      #
      # @example Basic usage
      #   render Bali::Timeline::Header::Component.new(text: 'Start')
      #
      # @example With color variant
      #   render Bali::Timeline::Header::Component.new(text: 'Milestone', color: :primary)
      #
      class Component < ApplicationViewComponent
        include Utils::ColorCalculator

        # Badge colours, keyed by Bali::Color::NAMES. `:outline` used to sit in
        # this table, which made a style look like a colour; it is `class:
        # 'badge-outline'` now, exactly as the `tag_class:` deprecation says.
        COLORS = {
          neutral: "badge-neutral",
          primary: "badge-primary",
          secondary: "badge-secondary",
          accent: "badge-accent",
          info: "badge-info",
          success: "badge-success",
          warning: "badge-warning",
          error: "badge-error",
          ghost: "badge-ghost"
        }.freeze

        DEFAULT_COLOR = :neutral

        # @param text [String] Text to display in the header badge
        # @param color [Symbol] Semantic colour of the badge (Bali::Color::NAMES)
        # @param custom_color [String, nil] Hex colour for the badge
        # @param tag_class [String, nil] @deprecated Removed in Bali 4.0. Use `color:`
        #   for the semantic variant and `class:` for anything on top of it.
        # @param options [Hash] Additional HTML attributes for the badge
        def initialize(text:, color: DEFAULT_COLOR, custom_color: nil, tag_class: nil, **options)
          @text = text
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          @color = @custom_color ? nil : Bali::Color.name!(self.class, color || DEFAULT_COLOR)
          @tag_class = tag_class
          @options = options

          warn_deprecated_tag_class if tag_class.present?
        end

        private

        attr_reader :text, :color, :custom_color, :tag_class, :options

        def badge_classes
          # `tag_class:` replaced the colour outright; `class:` adds to it.
          return class_names("badge", tag_class) if tag_class.present?

          class_names("badge", COLORS[color], options[:class])
        end

        def badge_style
          return options[:style] if custom_color.blank?

          "background-color: #{custom_color}; color: #{contrasting_text_color(custom_color)}"
        end

        def badge_options
          attrs = options.except(:class, :style).merge(class: badge_classes)
          attrs[:style] = badge_style if badge_style.present?
          attrs
        end

        def warn_deprecated_tag_class
          Bali.deprecator.warn(
            "Bali::Timeline::Header::Component `tag_class:` is deprecated. Use `color:` for " \
            "the semantic variant and `class:` for the rest, e.g. " \
            "`color: :primary, class: 'badge-outline'`."
          )
        end
      end
    end
  end
end
