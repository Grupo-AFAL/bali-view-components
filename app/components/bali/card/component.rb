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

      renders_one :title, ->(text, **options) do
        tag.h2(text, class: class_names('card-title', options[:class]), **options.except(:class))
      end

      renders_one :image,
                  lambda { |src: nil, href: nil, alt: nil, figure_class: nil, **opts, &block|
                    if src.present?
                      Image::Component.new(
                        src: src, href: href, alt: alt, figure_class: figure_class, **opts
                      )
                    else
                      tag.figure(class: figure_class, **opts, &block)
                    end
                  }

      renders_many :actions, Action::Component

      def initialize(style: :default, size: :md, side: false, image_full: false, shadow: true,
                     body_class: nil, **options)
        @style = style&.to_sym
        @size = size&.to_sym
        @side = side
        @image_full = image_full
        @shadow = shadow
        @body_class = body_class
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
          'shadow-sm' => @shadow
        )
      end

      def render_body?
        content.present? || header? || title? || actions.any?
      end

      def body_classes
        class_names('card-body', @body_class)
      end
    end
  end
end
