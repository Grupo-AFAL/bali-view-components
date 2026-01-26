# frozen_string_literal: true

module Bali
  module Loader
    class Component < ApplicationViewComponent
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

      BASE_CLASSES = 'loader-component flex flex-col items-center gap-4'

      # @param text [String, nil] Optional text to display below the loader
      # @param type [Symbol] Loader animation type (:spinner, :dots, :ring, :ball, :bars, :infinity)
      # @param size [Symbol] Loader size (:xs, :sm, :md, :lg, :xl)
      # @param color [Symbol, nil] Loader color (DaisyUI semantic colors)
      # @param hide_text [Boolean] If true, hides the text (for backwards compatibility)
      def initialize(text: nil, type: :spinner, size: :lg, color: nil, hide_text: false, **options)
        @text = text
        @type = type&.to_sym
        @size = size&.to_sym
        @color = color&.to_sym
        @hide_text = hide_text
        @options = options
      end

      private

      attr_reader :text, :options

      def loading_classes
        class_names(
          'loading',
          TYPES[@type],
          SIZES[@size],
          COLORS[@color]
        )
      end

      def container_classes
        class_names(
          BASE_CLASSES,
          options[:class]
        )
      end

      def container_attributes
        options.except(:class).merge(class: container_classes)
      end

      def show_text?
        !@hide_text
      end

      def display_text
        text || I18n.t('view_components.bali.loader.loading')
      end

      def aria_label
        display_text
      end

      def text_classes
        class_names(
          'text-xl font-semibold text-center',
          COLORS[@color]
        )
      end
    end
  end
end
