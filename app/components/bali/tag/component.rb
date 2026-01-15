# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      attr_reader :text, :href

      COLORS = {
        neutral: 'badge-neutral',
        primary: 'badge-primary',
        secondary: 'badge-secondary',
        accent: 'badge-accent',
        ghost: 'badge-ghost',
        info: 'badge-info',
        success: 'badge-success',
        warning: 'badge-warning',
        error: 'badge-error',
        danger: 'badge-error',
        link: 'badge-primary',
        black: 'badge-neutral',
        dark: 'badge-neutral',
        light: 'badge-ghost',
        white: 'badge-ghost'
      }.freeze

      SIZES = {
        xs: 'badge-xs',
        sm: 'badge-sm',
        md: 'badge-md',
        lg: 'badge-lg',
        xl: 'badge-xl',
        small: 'badge-sm',
        medium: 'badge-md',
        large: 'badge-lg',
        normal: nil
      }.freeze

      STYLES = {
        outline: 'badge-outline',
        soft: 'badge-soft',
        dash: 'badge-dash'
      }.freeze

      # rubocop:disable Metrics/ParameterLists
      def initialize(text:, href: nil, color: nil, custom_color: nil, size: nil, style: nil,
                     light: false, rounded: false, **options)
        # rubocop:enable Metrics/ParameterLists
        @text = text
        @href = href
        @color = color&.to_sym
        @custom_color = custom_color
        @size = size&.to_sym
        @style = style&.to_sym
        @light = light
        @rounded = rounded
        @options = options

        warn_deprecation if light
      end

      def tag_name
        href.present? ? :a : :div
      end

      def component_classes
        class_names(
          'tag-component',
          'badge',
          color_class,
          size_class,
          style_class,
          @rounded ? 'rounded-full' : nil,
          @options[:class]
        )
      end

      def custom_styles
        return @options[:style] if @custom_color.blank?

        [
          "background-color: #{@custom_color}",
          "color: #{contrasting_text_color(@custom_color)}",
          @options[:style]
        ].compact.join('; ')
      end

      def html_attributes
        attrs = @options.except(:class, :style)
        attrs[:href] = href if href.present?
        attrs[:style] = custom_styles if custom_styles.present?
        attrs
      end

      private

      def color_class
        COLORS[@color]
      end

      def size_class
        SIZES[@size]
      end

      def style_class
        return STYLES[@style] if @style.present?

        'badge-outline' if @light
      end

      def warn_deprecation
        Rails.logger.warn(
          '[DEPRECATION] Bali::Tag::Component `light` parameter is deprecated. ' \
          'Use `style: :outline` instead.'
        )
      end
    end
  end
end
