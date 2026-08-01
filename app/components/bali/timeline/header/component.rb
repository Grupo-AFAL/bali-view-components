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
        # Badge color variants
        COLORS = {
          default: "badge-neutral",
          primary: "badge-primary",
          secondary: "badge-secondary",
          accent: "badge-accent",
          success: "badge-success",
          warning: "badge-warning",
          error: "badge-error",
          info: "badge-info",
          ghost: "badge-ghost",
          outline: "badge-outline"
        }.freeze

        # @param text [String] Text to display in the header badge
        # @param color [Symbol] Color variant for the badge (see COLORS)
        # @param tag_class [String, nil] @deprecated Removed in Bali 4.0. Use `color:`
        #   for the semantic variant and `class:` for anything on top of it.
        # @param options [Hash] Additional HTML attributes for the badge
        def initialize(text:, color: :default, tag_class: nil, **options)
          @text = text
          @color = color.to_sym
          @tag_class = tag_class
          @options = options

          warn_deprecated_tag_class if tag_class.present?
        end

        private

        attr_reader :text, :color, :tag_class, :options

        def badge_classes
          # `tag_class:` replaced the colour outright; `class:` adds to it.
          return class_names("badge", tag_class) if tag_class.present?

          class_names("badge", COLORS.fetch(color, COLORS[:default]), options[:class])
        end

        def badge_options
          options.except(:class).merge(class: badge_classes)
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
