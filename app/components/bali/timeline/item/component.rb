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

        # Marker colours, keyed by Bali::Color::NAMES. Spelled out because
        # Tailwind only emits a class it can find literally in a source file.
        COLORS = {
          neutral: "text-neutral",
          primary: "text-primary",
          secondary: "text-secondary",
          accent: "text-accent",
          info: "text-info",
          success: "text-success",
          warning: "text-warning",
          error: "text-error",
          ghost: "text-base-content"
        }.freeze

        # Colours for the connecting line (hr element). `ghost` leaves it to
        # DaisyUI's own line colour, which is what the name means everywhere.
        LINE_COLORS = {
          neutral: "bg-neutral",
          primary: "bg-primary",
          secondary: "bg-secondary",
          accent: "bg-accent",
          info: "bg-info",
          success: "bg-success",
          warning: "bg-warning",
          error: "bg-error",
          ghost: ""
        }.freeze

        DEFAULT_COLOR = :ghost

        # @param heading [String, nil] Optional heading text for the item
        # @param icon [String, nil] Lucide icon name to display in the marker
        # @param color [Symbol] Semantic colour for the marker and line (Bali::Color::NAMES)
        # @param custom_color [String, nil] Hex colour for the marker and line
        # @param side [:start, :end] Which side of the line the content box lands on.
        #   Set by {Bali::Timeline::Component}, which owns the layout decision.
        # @param options [Hash] Additional HTML attributes for the container
        # rubocop:disable Metrics/ParameterLists
        def initialize(heading: nil, icon: nil, color: DEFAULT_COLOR, custom_color: nil,
                       side: :start, **options)
          # rubocop:enable Metrics/ParameterLists
          @heading = heading
          @icon = icon
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          @color = @custom_color ? nil : Bali::Color.name!(self.class, color || DEFAULT_COLOR)
          @side = side.to_sym
          @options = options
        end

        private

        attr_reader :heading, :icon, :color, :custom_color, :side, :options

        def content_box_classes
          class_names(
            SIDES.fetch(side, SIDES[:start]),
            "timeline-box",
            "timeline-content-box"
          )
        end

        def marker_classes
          class_names(MARKER_BASE_CLASSES, COLORS[color])
        end

        def marker_style
          "color: #{custom_color}" if custom_color
        end

        def line_classes
          LINE_COLORS.fetch(color, "")
        end

        def line_style
          "background-color: #{custom_color}" if custom_color
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
