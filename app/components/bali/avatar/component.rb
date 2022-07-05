# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      renders_one :picture, Picture::Component

      def initialize(form:,
                     attr_model_name:,
                     accepted_formats:,
                     placeholder_url: 'bulma-default.png',
                     **options)
        @form = form
        @attr_model_name = attr_model_name
        @accepted_formats = accepted_formats
        @placeholder_url = placeholder_url
        @options = prepend_class_name(options, 'avatar-component')
        @options = prepend_controller(@options, 'avatar')
      end
    end
  end
end
