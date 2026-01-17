# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      DEFAULTS = {
        start_at: 0,
        slides_per_view: 1,
        gap: 0,
        focus_at: :center
      }.freeze

      AUTOPLAY_INTERVALS = {
        disabled: false,
        slow: 5000,
        medium: 3000,
        fast: 1500
      }.freeze

      renders_many :items
      renders_one :arrows, Arrows::Component

      attr_reader :bullets_options

      def with_bullets(hidden: false, **opts)
        @bullets_options = { hidden: hidden, **opts }
      end

      def bullets?
        @bullets_options.present?
      end

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        slides_per_view: DEFAULTS[:slides_per_view],
        start_at: DEFAULTS[:start_at],
        autoplay: :disabled,
        gap: DEFAULTS[:gap],
        focus_at: DEFAULTS[:focus_at],
        breakpoints: nil,
        peek: nil,
        **options
      )
        @slides_per_view = slides_per_view
        @start_at = start_at
        @autoplay = resolve_autoplay(autoplay)
        @gap = gap
        @focus_at = resolve_focus_at(focus_at)
        @breakpoints = breakpoints
        @peek = peek
        @options = build_options(options)
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        items?
      end

      private

      def resolve_autoplay(value)
        return AUTOPLAY_INTERVALS[value] if value.is_a?(Symbol) && AUTOPLAY_INTERVALS.key?(value)

        value # Allow raw integer for custom intervals
      end

      def resolve_focus_at(value)
        value == :center ? 'center' : value
      end

      def build_options(options)
        opts = prepend_class_name(options, 'carousel-component glide')
        opts = prepend_controller(opts, 'carousel')
        prepend_values(opts, 'carousel', controller_values)
      end

      def controller_values
        {
          start_at: @start_at,
          per_view: @slides_per_view,
          autoplay: @autoplay,
          gap: @gap,
          focus_at: @focus_at,
          breakpoints: @breakpoints,
          peek: @peek
        }.compact
      end
    end
  end
end
