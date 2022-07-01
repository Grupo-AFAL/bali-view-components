# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      renders_many :images

      def initialize(selected_image: 0, **options)
        @options = options
        @options = prepend_class_name(@options, 'carousel-component glide')
        @options = prepend_controller(@options, 'carousel')
        @options = prepend_values(@options, 'carousel', { index: selected_image })
      end
    end
  end
end
