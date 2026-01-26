# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      # DaisyUI semantic colors
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
        # Legacy Bulma mappings (deprecated, remove in v2.0)
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
        # Legacy Bulma mappings (deprecated, remove in v2.0)
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
      def initialize(text:, href: nil, color: nil, custom_color: nil, size: nil,
                     style: nil, light: false, rounded: false, **options)
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

      private

      attr_reader :text, :href

      def tag_name
        href.present? ? :a : :div
      end

      def component_classes
        class_names(
          'badge',
          COLORS[@color],
          SIZES[@size],
          style_class,
          @rounded && 'rounded-full',
          @options[:class]
        )
      end

      def custom_styles
        styles = []

        if @custom_color.present?
          styles << "background-color: #{@custom_color}"
          styles << "color: #{contrasting_text_color(@custom_color)}"
        end

        styles << @options[:style] if @options[:style].present?
        styles.join('; ').presence
      end

      def html_attributes
        attrs = @options.except(:class, :style)
        attrs[:href] = href if href.present?
        attrs[:style] = custom_styles if custom_styles.present?
        attrs
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
