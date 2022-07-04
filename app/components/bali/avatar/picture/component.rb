# frozen_string_literal: true

module Bali
  module Avatar
    module Picture
      class Component < ApplicationViewComponent
        def initialize(picture:, **options)
          @picture = picture
          @options = options
          @options = prepend_class_name(@options, 'is-rounded')
          @options = prepend_data_attribute(@options, :image_preview_target, 'output')
        end

        def call
          image_tag(@picture, @options)
        end
      end
    end
  end
end
