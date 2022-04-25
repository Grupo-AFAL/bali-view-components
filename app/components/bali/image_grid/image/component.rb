# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class Component < ApplicationViewComponent
        renders_one :footer

        attr_reader :image_class

        def initialize(image_class: 'is-3by2')
          @image_class = image_class
        end
      end
    end
  end
end
