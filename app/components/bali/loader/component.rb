# frozen_string_literal: true

module Bali
  module Loader
    class Component < ApplicationViewComponent
      attr_reader :text

      TYPES = {
        spinner: 'loading-spinner',
        dots: 'loading-dots',
        ring: 'loading-ring',
        ball: 'loading-ball',
        bars: 'loading-bars',
        infinity: 'loading-infinity'
      }.freeze

      SIZES = {
        xs: 'loading-xs',
        sm: 'loading-sm',
        md: 'loading-md',
        lg: 'loading-lg',
        xl: 'loading-xl'
      }.freeze

      COLORS = {
        primary: 'text-primary',
        secondary: 'text-secondary',
        accent: 'text-accent',
        neutral: 'text-neutral',
        info: 'text-info',
        success: 'text-success',
        warning: 'text-warning',
        error: 'text-error'
      }.freeze

      def initialize(text: nil, type: :spinner, size: :lg, color: nil, **options)
        @text = text
        @type = type&.to_sym
        @size = size&.to_sym
        @color = color&.to_sym
        @options = options
      end

      def loading_classes
        class_names(
          'loading',
          TYPES[@type],
          SIZES[@size],
          COLORS[@color],
          @options[:class]
        )
      end

      def container_classes
        class_names(
          'loader-component',
          'flex flex-col items-center gap-4'
        )
      end

      def show_text?
        text.present? || !@options[:hide_text]
      end

      def display_text
        text || I18n.t('view_components.bali.loader.loading')
      end
    end
  end
end
