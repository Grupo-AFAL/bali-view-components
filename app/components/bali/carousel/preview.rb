module Bali
  module Carousel
    class Preview < ApplicationViewComponentPreview
      include ActionView::Helpers::AssetUrlHelper

      def default
        render(Carousel::Component.new) do |c|
          c.image do
            image_tag('https://via.placeholder.com/320x244.png', class: 'image-center')
          end
        end
      end
    end
  end
end
