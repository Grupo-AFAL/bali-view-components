# frozen_string_literal: true

module Bali
  module Timeline
    # Timeline component for displaying chronological sequences of events.
    #
    # Uses DaisyUI timeline component with semantic HTML structure.
    #
    # @example Basic usage
    #   render Bali::Timeline::Component.new do |c|
    #     c.with_tag_header(text: 'Start')
    #     c.with_tag_item(heading: 'Event 1') { 'Content' }
    #     c.with_tag_item(heading: 'Event 2') { 'Content' }
    #   end
    #
    class Component < ApplicationViewComponent
      # Base classes for the timeline container
      BASE_CLASSES = 'timeline timeline-vertical'

      # Position modifiers for timeline layout
      # - :left   - Default, items on left side
      # - :center - Alternating items on both sides
      # - :right  - Items on right side (uses snap-icon modifier)
      POSITIONS = {
        left: '',
        center: '',
        right: 'timeline-snap-icon'
      }.freeze

      renders_many :tags, types: {
        header: Timeline::Header::Component,
        item: Timeline::Item::Component
      }

      # @param position [:left, :center, :right] Timeline layout position
      # @param options [Hash] Additional HTML attributes for the container
      def initialize(position: :left, **options)
        @position = position.to_sym
        @options = options
      end

      private

      attr_reader :position, :options

      def component_classes
        class_names(
          BASE_CLASSES,
          POSITIONS.fetch(position, ''),
          options[:class],
          'timeline-centered' => position == :center
        )
      end

      def container_options
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
