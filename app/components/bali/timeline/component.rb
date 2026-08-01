# frozen_string_literal: true

module Bali
  module Timeline
    # Timeline component for displaying chronological sequences of events.
    #
    # Uses DaisyUI timeline component with semantic HTML structure. Every entry
    # renders exactly once: the side of the line it lands on is decided here, in
    # Ruby, instead of emitting both sides and hiding one with CSS.
    #
    # @example Basic usage
    #   render Bali::Timeline::Component.new do |c|
    #     c.with_header(text: 'Start')
    #     c.with_item(heading: 'Event 1') { 'Content' }
    #     c.with_item(heading: 'Event 2') { 'Content' }
    #   end
    #
    class Component < ApplicationViewComponent
      # Base classes for the timeline container
      BASE_CLASSES = "timeline timeline-vertical"

      # Position modifiers for timeline layout
      # - :left   - Default, items on the start side
      # - :center - Items alternate between both sides
      # - :right  - Items on the end side (uses DaisyUI's snap-icon modifier)
      POSITIONS = {
        left: "",
        center: "timeline-centered",
        right: "timeline-snap-icon"
      }.freeze

      # Side an item's content box lands on, per position. :center is absent on
      # purpose: it has no fixed side, it alternates.
      SIDES = {
        left: :start,
        right: :end
      }.freeze

      renders_many :entries, types: {
        header: { renders: Timeline::Header::Component, as: :header },
        item: {
          as: :item,
          renders: lambda { |**options|
            Timeline::Item::Component.new(side: next_item_side, **options)
          }
        }
      }

      # @param position [:left, :center, :right] Timeline layout position
      # @param options [Hash] Additional HTML attributes for the container
      def initialize(position: :left, **options)
        @position = position.to_sym
        @options = options
        @item_index = 0
      end

      # @deprecated Removed in Bali 4.0. Use {#with_item}.
      def with_tag_item(**options, &block)
        Bali.deprecator.warn(
          "Bali::Timeline::Component#with_tag_item is deprecated. Use `with_item` instead."
        )

        with_item(**options, &block)
      end

      # @deprecated Removed in Bali 4.0. Use {#with_header}.
      def with_tag_header(**options, &block)
        Bali.deprecator.warn(
          "Bali::Timeline::Component#with_tag_header is deprecated. Use `with_header` instead."
        )

        with_header(**options, &block)
      end

      private

      attr_reader :position, :options

      # Alternation counts items only, so a header between two items no longer
      # flips the side the way the old `li:nth-child(odd)` rule did.
      def next_item_side
        return SIDES.fetch(position, :start) unless position == :center

        side = @item_index.even? ? :start : :end
        @item_index += 1
        side
      end

      def component_classes
        class_names(BASE_CLASSES, POSITIONS.fetch(position, ""), options[:class])
      end

      def container_options
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
