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

        @options = prepend_class_name(options, image_field_classes)
        @options = prepend_controller(@options, 'image-field')

        @image_options = prepend_data_attribute(image_options, 'image-field-target', 'output')
      end

      private

      def image_field_classes
        class_names(
          'image-field-component group relative w-fit',
          '[&_.image_img]:h-full',
          '[&_.image-figure]:transition-all [&_.image-figure]:duration-500',
          '[&_.image-figure]:[backface-visibility:hidden]',
          '[&_.clear-image-button]:absolute [&_.clear-image-button]:rounded-full',
          '[&_.clear-image-button]:hidden [&_.clear-image-button]:justify-center',
          '[&_.clear-image-button]:items-center',
          '[&_.clear-image-button]:bg-base-200 [&_.clear-image-button]:text-base-content',
          '[&_.clear-image-button]:opacity-80',
          '[&_.clear-image-button]:-top-3 [&_.clear-image-button]:-right-3',
          '[&_.clear-image-button]:size-8',
          'hover:[&_.clear-image-button]:flex max-md:[&_.clear-image-button]:flex',
          '[&_.image-input-container]:absolute [&_.image-input-container]:inset-0',
          '[&_.image-input-container]:flex [&_.image-input-container]:justify-center',
          '[&_.image-input-container]:items-center [&_.image-input-container]:cursor-pointer',
          '[&_.image-input-container_.icon-component]:hidden',
          '[&_.image-input-container_.control]:hidden',
          'hover:[&_.image-input-container]:bg-base-content/20',
          'hover:[&_.image-input-container]:backdrop-blur-sm',
          'hover:[&_.image-input-container_.icon-component]:flex',
          'max-md:[&_.image-input-container]:bg-base-content/20',
          'max-md:[&_.image-input-container]:backdrop-blur-sm',
          'max-md:[&_.image-input-container_.icon-component]:flex'
        )
      end
    end
  end
end
