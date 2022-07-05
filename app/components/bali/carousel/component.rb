# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      renders_many :items

      renders_one :title
      renders_one :footer
      renders_one :controls, Controls::Component

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
        @options = prepend_class_name(@options, 'glide')
        @options = prepend_controller(@options, 'carousel')
        @options = prepend_values(@options, 'carousel', controller_values)
      end

      def controller_values
        {
          index: @start_at,
          per_view: @per_view,
          autoplay: @autoplay,
          gap: @gap,
          focus_at: @focus_at,
          breakpoints: @breakpoints,
          peek: @peek
        }.compact
      end

      def before_render
        return if controls.blank?

        controls.bullets_count = items.size
      end

      def render?
        items?
      end
    end
  end
end
