# frozen_string_literal: true

module Bali
  module Avatar
    module Picture
      class Component < ApplicationViewComponent
        def initialize(image_url:, **options)
          @image_url = image_url
          @options = prepend_class_name(options, 'is-rounded')
          @options = prepend_data_attribute(@options, :avatar_target, 'output')
        end

        def call
          image_tag(@image_url, @options)
        end
      end
    end
  end
end
