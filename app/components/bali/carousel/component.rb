# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      renders_many :items

      renders_one :bullets, Bullets::Component
      renders_one :arrows, Arrows::Component

      def initialize(
        start_at: 0,
        per_view: 1,
        autoplay: false,
        gap: 0,
        focus_at: 0,
        **options
      )
        @start_at = start_at
        @per_view = per_view
        @autoplay = autoplay
        @gap = gap
        @focus_at = focus_at
        @breakpoints = options.delete(:breakpoints)
        @peek = options.delete(:peek)

        @options = options
        @options = prepend_class_name(@options, 'carousel-component glide')
        @options = prepend_controller(@options, 'carousel')
        @options = prepend_values(@options, 'carousel', controller_values)
      end

      def controller_values
        {
          start_at: @start_at,
          per_view: @per_view,
          autoplay: @autoplay,
          gap: @gap,
          focus_at: @focus_at,
          breakpoints: @breakpoints,
          peek: @peek
        }
      end

      def before_render
        return if bullets.blank?

        bullets.count = items.size
      end

      def render?
        items?
      end
    end
  end
end
