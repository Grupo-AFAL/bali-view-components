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
      # @example Tracking entry
      #   render Bali::Timeline::Item::Component.new(
      #     heading: 'In transit',
      #     state: :current,
      #     timestamp: 'Jul 29, 08:40 · Unit 12',
      #     href: '/shipments/42'
      #   )
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

        # `state:` is sugar over `icon:`/`color:` for the tracking look.
        # `:done` is `:primary` on purpose — a normal tracking line is not a
        # celebration; pass `color: :success` for the green check.
        STATES = {
          done: { icon: "circle-check", color: :primary },
          current: { icon: "circle-dot", color: :primary },
          pending: { icon: "circle", color: :ghost }
        }.freeze

        # Classes the clickable box adds so hovering reads as interactive
        CLICKABLE_BOX_CLASSES = "hover:bg-base-200 transition-colors"

        # Muted metadata line, custody-chain style
        TIMESTAMP_CLASSES = "text-sm text-base-content/60"

        # Set by the parent so the line below this item takes the colour of the
        # item that follows it — a coloured line then reads as "travelled this
        # far". Rendered standalone, the line keeps this item's own colour.
        attr_writer :next_item_for_line

        # Rich timestamps (a `<time>` tag, a tooltip) go through the slot, which
        # wins over the `timestamp:` keyword when both are given.
        renders_one :timestamp

        # @param heading [String, nil] Optional heading text for the item
        # @param icon [String, nil] Lucide icon name to display in the marker
        # @param color [Symbol] Semantic colour for the marker and line (Bali::Color::NAMES)
        # @param custom_color [String, nil] Hex colour for the marker and line
        # @param state [:done, :current, :pending, nil] Tracking sugar: resolves the
        #   marker icon and colour (see STATES); `icon:`/`color:` given explicitly win.
        #   `:pending` also mutes the heading.
        # @param timestamp [String, Time, Date, nil] Muted metadata line. Rendered on
        #   the opposite side of the content box, or inside the box when the timeline
        #   is compact. Non-strings are localized with `l(format: :short)`.
        # @param href [String, nil] Renders the content box as a link
        # @param side [:start, :end] Which side of the line the content box lands on.
        #   Set by {Bali::Timeline::Component}, which owns the layout decision.
        # @param compact [Boolean] Whether the parent timeline is compact. Set by
        #   {Bali::Timeline::Component}; moves the timestamp inside the box.
        # @param options [Hash] Additional HTML attributes for the content box
        # rubocop:disable Metrics/ParameterLists
        def initialize(heading: nil, icon: nil, color: nil, custom_color: nil, state: nil,
                       timestamp: nil, href: nil, side: :start, compact: false, **options)
          # rubocop:enable Metrics/ParameterLists
          @state = validated_state(state)
          state_defaults = @state ? STATES.fetch(@state) : {}
          @heading = heading
          @icon = icon || state_defaults[:icon]
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          resolved_color = color || state_defaults[:color] || DEFAULT_COLOR
          @color = @custom_color ? nil : Bali::Color.name!(self.class, resolved_color)
          @timestamp_value = timestamp
          @href = href
          @side = side.to_sym
          @compact = compact
          @options = options
        end

        # Public because the previous item in the timeline colours its lower
        # line by asking this item — see `next_item_for_line=`.
        def line_classes
          LINE_COLORS.fetch(color, "")
        end

        def line_style
          "background-color: #{custom_color}" if custom_color
        end

        private

        attr_reader :heading, :icon, :color, :custom_color, :state, :href, :side, :compact,
                    :options

        def content_box_classes
          class_names(
            SIDES.fetch(side, SIDES[:start]),
            "timeline-box",
            "timeline-content-box",
            href.present? && CLICKABLE_BOX_CLASSES,
            options[:class]
          )
        end

        def box_tag_name
          href.present? ? :a : :div
        end

        def content_box_options
          attrs = options.except(:class).merge(class: content_box_classes)
          attrs[:href] = href if href.present?
          attrs
        end

        def heading_classes
          class_names("font-semibold", "text-base-content/60" => state == :pending)
        end

        def marker_classes
          class_names(MARKER_BASE_CLASSES, COLORS[color])
        end

        def marker_style
          "color: #{custom_color}" if custom_color
        end

        def line_after_source
          @next_item_for_line || self
        end

        def line_after_classes
          line_after_source.line_classes
        end

        def line_after_style
          line_after_source.line_style
        end

        def timestamp_present?
          timestamp? || @timestamp_value.present?
        end

        def timestamp_content
          return timestamp if timestamp?
          return @timestamp_value if @timestamp_value.is_a?(String)

          helpers.l(@timestamp_value, format: :short)
        end

        # The muted timestamp sits on the free side of the line; in compact
        # there is no free side, so it becomes a line inside the box.
        def timestamp_side_classes
          opposite = side == :end ? :start : :end
          class_names(SIDES.fetch(opposite), TIMESTAMP_CLASSES)
        end

        def box_timestamp_classes
          TIMESTAMP_CLASSES
        end

        def default_icon
          "circle"
        end

        def display_icon
          icon || default_icon
        end

        def validated_state(state)
          return nil if state.nil?

          key = state.to_sym
          return key if STATES.key?(key)

          raise ArgumentError,
                "Bali::Timeline::Item::Component: unknown state #{key.inspect}. " \
                "Valid: #{STATES.keys.map(&:inspect).join(', ')}."
        end
      end
    end
  end
end
