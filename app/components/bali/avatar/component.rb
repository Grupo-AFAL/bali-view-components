# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      renders_one :file_field_input

      def initialize(picture:,
                     placeholder_url: 'https://bulma.io/images/placeholders/256x256.png',
                     **options)
        @picture = picture
        @placeholder_url = placeholder_url
        @options = prepend_class_name(options, 'avatar-component')
        @options = prepend_controller(@options, 'image-preview')
      end
    end
  end
end
