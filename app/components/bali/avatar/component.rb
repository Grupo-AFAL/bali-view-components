# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      renders_one :picture, Picture::Component

      SIZES = {
        xs: 'w-8',
        sm: 'w-12',
        md: 'w-16',
        lg: 'w-24',
        xl: 'w-32'
      }.freeze

      def initialize(form:, method:, placeholder_url:, formats: %i[jpg jpeg png], size: :xl,
                     **options)
        @form = form
        @method = method
        @formats = formats
        @placeholder_url = placeholder_url
        @size = size&.to_sym
        @options = options
      end

      def container_classes
        class_names(
          'avatar-component',
          'relative',
          'w-fit',
          @options[:class]
        )
      end

      def avatar_classes
        class_names(
          'avatar',
          SIZES[@size]
        )
      end

      def accepted_formats
        @formats.map { |f| ".#{f}," }.join(' ')
      end

      def default_picture
        image_tag(@placeholder_url, class: 'rounded-full', data: { 'avatar-target': 'output' })
      end

      def stimulus_controller
        'avatar'
      end
    end
  end
end
