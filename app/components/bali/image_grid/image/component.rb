# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class Component < ApplicationViewComponent
        renders_one :footer, 'Bali::ImageGrid::Image::FooterComponent'

        attr_reader :image_ratio

        # image_ratio: aspect ratio class (aspect-[3/2], aspect-square, etc.)
        # column_size: kept for backwards compatibility but now ignored (grid handles column sizing)
        def initialize(image_ratio: 'aspect-[3/2]', _column_size: nil, **options)
          @image_ratio = image_ratio
          @options = prepend_class_name(options, 'image-grid-item')
        end
      end

      class FooterComponent < ApplicationViewComponent
        def initialize(**options)
          @options = prepend_class_name(options, 'card-footer')
        end

        def call
          tag.footer(**@options) { content }
        end
      end
    end
  end
end
