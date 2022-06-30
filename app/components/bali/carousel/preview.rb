module Bali
  module Carousel
    class Preview < ApplicationViewComponentPreview
      include ActionView::Helpers::AssetUrlHelper

      def default
        render(Carousel::Component.new(images: ['https://via.placeholder.com/320x244.png']))
      end
    end
  end
end
