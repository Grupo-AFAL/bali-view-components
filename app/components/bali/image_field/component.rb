# frozen_string_literal: true

module Bali
  module ImageField
    class Component < ApplicationViewComponent
      renders_one :input, Bali::ImageField::Input::Component
      renders_one :clear_button

      def initialize(
        image_url = nil, placeholder_url: 'https://placehold.jp/128x128.png',
        image_options: { class: 'image is-128x128' }, **options
      )
        @image_url = image_url || placeholder_url
        @placeholder_url = placeholder_url

        @options = prepend_class_name(options, 'image-field-component')
        @options = prepend_controller(@options, 'image-field')

        @image_options = prepend_data_attribute(image_options, 'image-field-target', 'output')
      end
    end
  end
end
