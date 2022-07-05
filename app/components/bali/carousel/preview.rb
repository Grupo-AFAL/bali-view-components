module Bali
  module Carousel
    class Preview < ApplicationViewComponentPreview
      # Carousel
      # -------------
      # This will render the basic carousel
      def default
        render(Carousel::Component.new) do |c|
          c.item do
            image_tag('https://via.placeholder.com/320x244.png', class: 'image-center')
          end
        end
      end

      # Carousel with options
      # -------------
      # This will render the carousel as if it were a slider
      def with_options
        render(Carousel::Component.new(data: { 'carousel-type-value': 'slider' })) do |c|
          c.item do
            image_tag('https://via.placeholder.com/320x244.png', class: 'image-center')
          end

          c.item do
            image_tag('https://via.placeholder.com/320x244.png', class: 'image-center')
          end
        end
      end
    end
  end
end
