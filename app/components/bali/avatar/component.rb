# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      renders_one :picture, Picture::Component

      def initialize(form:,
                     method:,
                     formats: %i[jpg jpeg png],
                     placeholder_url: 'bulma-default.png',
                     **options)
        @form = form
        @method = method
        @formats = formats
        @placeholder_url = placeholder_url
        @options = prepend_class_name(options, 'avatar-component')
        @options = prepend_controller(@options, 'avatar')
      end

      def accepted_formats
        @formats.map { |f| ".#{f}," }
      end
    end
  end
end
