# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      renders_many :items

      def initialize(
        start_at: 0,
        per_view: 1,
        autoplay: false,
        gap: 0,
        focus_at: 'center',
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
    end
  end
end
