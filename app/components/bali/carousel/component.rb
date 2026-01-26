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

      # NOTE: bullets uses a custom method instead of renders_one because it needs
      # to know the item count at render time, which is only available after items
      # are added. ViewComponent slot lambdas don't have access to the parent component.
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
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        items?
      end

      private

      def component_classes
        class_names(
          'carousel-component',
          'glide',
          @options[:class]
        )
      end

      def component_data
        base_data = {
          controller: 'carousel',
          'carousel-start-at-value' => @start_at,
          'carousel-per-view-value' => @slides_per_view,
          'carousel-autoplay-value' => @autoplay,
          'carousel-gap-value' => @gap,
          'carousel-focus-at-value' => @focus_at,
          'carousel-breakpoints-value' => @breakpoints&.to_json,
          'carousel-peek-value' => @peek
        }.compact

        base_data.merge(@options[:data] || {})
      end

      def html_options
        @options.except(:class, :data)
      end

      def resolve_autoplay(value)
        return AUTOPLAY_INTERVALS[value] if value.is_a?(Symbol) && AUTOPLAY_INTERVALS.key?(value)

        value
      end

      def resolve_focus_at(value)
        value == :center ? 'center' : value
      end
    end
  end
end
