# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      renders_one :picture, Picture::Component
      renders_one :placeholder

      SIZES = {
        xs: 'w-8',
        sm: 'w-12',
        md: 'w-16',
        lg: 'w-24',
        xl: 'w-32'
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
      def initialize(form: nil, method: nil, placeholder_url: nil, formats: %i[jpg jpeg png],
                     size: :xl, shape: :square, mask: nil, status: nil, ring: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        @form = form
        @method = method
        @formats = formats
        @placeholder_url = placeholder_url
        @size = size&.to_sym
        @shape = shape&.to_sym
        @mask = mask&.to_sym
        @status = status&.to_sym
        @ring = ring&.to_sym
        @options = options
      end

      def container_classes
        class_names(
          'avatar-component',
          'avatar',
          { 'relative' => uploadable? },
          STATUSES[@status],
          { 'avatar-placeholder' => placeholder? },
          @options[:class]
        )
      end

      def avatar_inner_classes
        class_names(
          SIZES[@size],
          shape_classes,
          { 'aspect-square' => !@mask },
          ring_classes
        )
      end

      def shape_classes
        return MASKS[@mask] if @mask

        SHAPES[@shape] || SHAPES[:square]
      end

      def ring_classes
        return unless @ring

        class_names(
          'ring-2',
          'ring-offset-base-100',
          'ring-offset-2',
          RING_COLORS[@ring]
        )
      end

      def accepted_formats
        @formats.map { |f| ".#{f}" }.join(', ')
      end

      def default_picture
        return unless @placeholder_url

        image_tag(
          @placeholder_url,
          class: 'w-full h-full object-cover',
          data: uploadable? ? { 'avatar-target': 'output' } : {}
        )
      end

      def upload_button_classes
        class_names(
          'absolute',
          '-bottom-1',
          '-right-1',
          'bg-base-200',
          'rounded-full',
          'w-10',
          'h-10',
          'flex',
          'justify-center',
          'items-center',
          'cursor-pointer',
          'hover:bg-base-300',
          'focus-within:ring-2',
          'focus-within:ring-primary',
          'focus-within:ring-offset-2',
          'transition-colors',
          'duration-200'
        )
      end

      def stimulus_controller
        'avatar'
      end

      def uploadable?
        @form.present? && @method.present?
      end

      def placeholder?
        placeholder.present? && !picture? && !@placeholder_url
      end

      def placeholder_classes
        class_names(
          'bg-neutral',
          'text-neutral-content',
          placeholder_text_size
        )
      end

      private

      def placeholder_text_size
        case @size
        when :xs then 'text-xs'
        when :sm then 'text-sm'
        when :md then 'text-base'
        when :xl then 'text-3xl'
        else 'text-xl' # :lg and default
        end
      end
    end
  end
end
