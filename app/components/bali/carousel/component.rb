# frozen_string_literal: true

module Bali
  module Carousel
    class Component < ApplicationViewComponent
      def initialize(images:, selected_image: 0)
        @images = images
        @selected_image = selected_image
      end

      def classes
        class_names('carousel-componet glide')
      end
    end
  end
end
