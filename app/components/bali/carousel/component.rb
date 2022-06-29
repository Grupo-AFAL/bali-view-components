module Bali
  module Carousel
    class Component < ApplicationViewComponent
      def initialize(images:, selected_image: 0)
        @images = images
        @selected_image = selected_image
      end

      def classes; end
    end
  end
end
