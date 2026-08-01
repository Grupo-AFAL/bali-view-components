# frozen_string_literal: true

module Bali
  module Timeline
    module Item
      # Timeline item component for individual timeline entries.
      #
      # Uses DaisyUI's timeline-start, timeline-middle, timeline-end structure.
      # The heading and the content are emitted once, in the single content box
      # the parent timeline assigned through `side:`.
      #
      # @example Basic usage
      #   render Bali::Timeline::Item::Component.new(heading: 'Event Title') do
      #     'Event content goes here'
      #   end
      #
      # @example With icon and color
      #   render Bali::Timeline::Item::Component.new(
      #     heading: 'Completed',
      #     icon: 'check',
      #     color: :success
      #   ) { 'Task finished' }
      #
      class Component < ApplicationViewComponent
        # Base classes for the timeline item marker
        MARKER_BASE_CLASSES = "timeline-middle"

        # DaisyUI grid area the single content box is placed in
        SIDES = {
          start: "timeline-start",
          end: "timeline-end"
        }.freeze

        # Color variants for the marker icon
        COLORS = {
          default: "text-base-content",
          primary: "text-primary",
          secondary: "text-secondary",
          accent: "text-accent",
          success: "text-success",
          warning: "text-warning",
          error: "text-error",
          info: "text-info"
        }.freeze

        # Color variants for the connecting line (hr element)
        LINE_COLORS = {
          default: "",
          primary: "bg-primary",
          secondary: "bg-secondary",
          accent: "bg-accent",
          success: "bg-success",
          warning: "bg-warning",
          error: "bg-error",
          info: "bg-info"
        }.freeze

        # @param heading [String, nil] Optional heading text for the item
        # @param icon [String, nil] Lucide icon name to display in the marker
        # @param color [:default, :primary, :secondary, :accent, :success, :warning, :error, :info]
        #   Color variant for the marker and line
        # @param side [:start, :end] Which side of the line the content box lands on.
        #   Set by {Bali::Timeline::Component}, which owns the layout decision.
        # @param options [Hash] Additional HTML attributes for the container
        def initialize(heading: nil, icon: nil, color: :default, side: :start, **options)
          @heading = heading
          @icon = icon
          @color = color.to_sym
          @side = side.to_sym
          @options = options
        end

        private

        attr_reader :heading, :icon, :color, :side, :options

        def content_box_classes
          class_names(
            SIDES.fetch(side, SIDES[:start]),
            "timeline-box",
            "timeline-content-box"
          )
        end

        def marker_classes
          class_names(
            MARKER_BASE_CLASSES,
            COLORS.fetch(color, COLORS[:default])
          )
        end

        def line_classes
          LINE_COLORS.fetch(color, "")
        end

        def default_icon
          "circle"
        end

        def display_icon
          icon || default_icon
        end
      end
    end
  end
end
