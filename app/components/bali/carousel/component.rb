# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      def initialize(images:, selected_image: 0, **options)
        @images = images
        @optinos = prepend_class_name(options, 'carousel-componet glide')
        @options = prepend_controller(@options, 'carousel')
        @options = prepend_data_attribute(@options, 'carousel-index-value', selected_image)
      end
    end
  end
end
