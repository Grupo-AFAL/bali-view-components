# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class Component < ApplicationViewComponent
        renders_one :footer, 'Bali::ImageGrid::Image::FooterComponent'

        attr_reader :image_class

        def initialize(image_class: 'is-3by2', **options)
          @image_class = image_class
          @options = prepend_class_name(options, 'column is-one-quarter')
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
