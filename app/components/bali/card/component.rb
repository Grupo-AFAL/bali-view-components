# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationViewComponent
      STYLES = {
        default: '',
        bordered: 'card-border',
        dash: 'card-dash'
      }.freeze

      SIZES = {
        xs: 'card-xs',
        sm: 'card-sm',
        md: '',
        lg: 'card-lg',
        xl: 'card-xl'
      }.freeze

      renders_one :header, Header::Component

      renders_one :image, ->(src: nil, **options, &block) do
        if src.present?
          Image::Component.new(src: src, **options)
        else
          tag.slot(**options, &block)
        end
      end

      renders_many :footer_items, FooterItem::Component

      def initialize(style: :default, size: :md, side: false, image_full: false, shadow: true,
                     **options)
        @style = style&.to_sym
        @size = size&.to_sym
        @side = side
        @image_full = image_full
        @shadow = shadow
        @options = options

        build_options
      end

      private

      def build_options
        @options = prepend_class_name(@options, card_classes)
      end

      def card_classes
        class_names(
          'card',
          'bg-base-100',
          STYLES[@style],
          SIZES[@size],
          'card-side' => @side,
          'image-full' => @image_full,
          'shadow-lg' => @shadow
        )
      end
    end
  end
end
