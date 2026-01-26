# frozen_string_literal: true

module Bali
  module ImageField
    class Component < ApplicationViewComponent
      # Default placeholder using data URI to avoid external dependency
      DEFAULT_PLACEHOLDER_URL = 'https://placehold.jp/128x128.png'
      private_constant :DEFAULT_PLACEHOLDER_URL

      SIZES = {
        xs: 'size-16',
        sm: 'size-24',
        md: 'size-32',
        lg: 'size-40',
        xl: 'size-48'
      }.freeze

      DEFAULT_SIZE = :md
      private_constant :DEFAULT_SIZE

      renders_one :input, Bali::ImageField::Input::Component
      renders_one :clear_button

      attr_reader :size

      def initialize(src: nil, placeholder_url: DEFAULT_PLACEHOLDER_URL, size: DEFAULT_SIZE,
                     **options)
        @src = src || placeholder_url
        @placeholder_url = placeholder_url
        @size = size&.to_sym || DEFAULT_SIZE
        @options = options
      end

      private

      attr_reader :src, :placeholder_url, :options

      def container_classes
        class_names(
          'image-field-component',
          'group relative w-fit',
          options[:class]
        )
      end

      def container_options
        opts = options.except(:class)
        opts[:class] = container_classes
        prepend_controller(opts, 'image-field')
      end

      def image_classes
        class_names(
          'rounded-lg object-cover',
          SIZES[size]
        )
      end

      def image_options
        {
          class: image_classes,
          data: { image_field_target: 'output' },
          loading: 'lazy',
          decoding: 'async',
          alt: ''
        }
      end

      def placeholder_options
        {
          class: 'hidden',
          data: { image_field_target: 'placeholder' },
          loading: 'lazy',
          decoding: 'async',
          alt: ''
        }
      end

      def clear_button_classes
        class_names(
          'clear-image-button',
          'btn btn-circle btn-sm btn-ghost',
          'absolute -top-2 -right-2',
          'bg-base-200 text-base-content opacity-80',
          'hidden group-hover:flex max-md:flex'
        )
      end
    end
  end
end
