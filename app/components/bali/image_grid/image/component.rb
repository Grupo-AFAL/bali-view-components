# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class Component < ApplicationViewComponent
        renders_one :footer, 'Bali::ImageGrid::Image::FooterComponent'

        attr_reader :image_ratio

        def initialize(image_ratio: 'is-3by2', column_size: 'is-one-quarter', **options)
          @image_ratio = image_ratio
          @options = prepend_class_name(options, "column #{column_size}")
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
