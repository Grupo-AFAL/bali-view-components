module Bali
  module Carousel
    class Preview < ApplicationViewComponentPreview
      def default
        render(Carousel::Component.new)
      end
    end
  end
end
