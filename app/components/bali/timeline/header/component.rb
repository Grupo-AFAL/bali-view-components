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
          default: 'badge-neutral',
          primary: 'badge-primary',
          secondary: 'badge-secondary',
          accent: 'badge-accent',
          success: 'badge-success',
          warning: 'badge-warning',
          error: 'badge-error',
          info: 'badge-info',
          ghost: 'badge-ghost',
          outline: 'badge-outline'
        }.freeze

        # @param text [String] Text to display in the header badge
        # @param color [Symbol] Color variant for the badge (see COLORS)
        # @param tag_class [String, nil] DEPRECATED: Use color param instead
        # @param options [Hash] Additional HTML attributes for the container
        def initialize(text:, color: :default, tag_class: nil, **options)
          @text = text
          @color = color.to_sym
          @tag_class = tag_class
          @options = options
        end

        private

        attr_reader :text, :color, :tag_class, :options

        def badge_classes
          # Support legacy tag_class for backwards compatibility
          if tag_class.present?
            class_names('badge', tag_class)
          else
            class_names('badge', COLORS.fetch(color, COLORS[:default]))
          end
        end
      end
    end
  end
end
