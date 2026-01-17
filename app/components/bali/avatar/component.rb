# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      renders_one :picture, ->(image_url:, **options) {
        Picture::Component.new(image_url: image_url, **options)
      }
      renders_one :placeholder

      SIZES = {
        xs: 'w-8',
        sm: 'w-12',
        md: 'w-16',
        lg: 'w-24',
        xl: 'w-32'
      }.freeze

      PLACEHOLDER_TEXT_SIZES = {
        xs: 'text-xs',
        sm: 'text-sm',
        md: 'text-base',
        lg: 'text-xl',
        xl: 'text-3xl'
      }.freeze

      SHAPES = {
        square: 'rounded',
        rounded: 'rounded-xl',
        circle: 'rounded-full'
      }.freeze

      MASKS = {
        heart: 'mask mask-heart',
        squircle: 'mask mask-squircle',
        hexagon: 'mask mask-hexagon-2',
        triangle: 'mask mask-triangle',
        diamond: 'mask mask-diamond',
        pentagon: 'mask mask-pentagon',
        star: 'mask mask-star'
      }.freeze

      STATUSES = {
        online: 'avatar-online',
        offline: 'avatar-offline'
      }.freeze

      RING_COLORS = {
        primary: 'ring-primary',
        secondary: 'ring-secondary',
        accent: 'ring-accent',
        neutral: 'ring-neutral',
        success: 'ring-success',
        warning: 'ring-warning',
        error: 'ring-error',
        info: 'ring-info'
      }.freeze

      # rubocop:disable Metrics/ParameterLists
      def initialize(src: nil, size: :md, shape: :circle, mask: nil,
                     status: nil, ring: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        @src = src
        @size = size&.to_sym
        @shape = shape&.to_sym
        @mask = mask&.to_sym
        @status = status&.to_sym
        @ring = ring&.to_sym
        @options = options
      end

      def container_classes
        class_names(
          'avatar',
          STATUSES[@status],
          placeholder? && 'avatar-placeholder',
          @options[:class]
        )
      end

      def inner_classes
        class_names(
          SIZES[@size],
          shape_classes,
          @mask.nil? && 'aspect-square',
          ring_classes
        )
      end

      def placeholder_classes
        class_names(
          'bg-neutral',
          'text-neutral-content',
          placeholder_text_size
        )
      end

      private

      def shape_classes
        @mask ? MASKS[@mask] : SHAPES.fetch(@shape, SHAPES[:circle])
      end

      def ring_classes
        return unless @ring

        class_names(
          'ring-2 ring-offset-base-100 ring-offset-2',
          RING_COLORS[@ring]
        )
      end

      def placeholder?
        placeholder.present? && !picture? && @src.blank?
      end

      def placeholder_text_size
        PLACEHOLDER_TEXT_SIZES.fetch(@size, 'text-xl')
      end
    end
  end
end
