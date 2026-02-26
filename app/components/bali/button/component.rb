# frozen_string_literal: true

module Bali
  module Button
    class Component < ApplicationViewComponent
      VARIANTS = {
        primary: "btn-primary",
        secondary: "btn-secondary",
        accent: "btn-accent",
        info: "btn-info",
        success: "btn-success",
        warning: "btn-warning",
        error: "btn-error",
        ghost: "btn-ghost",
        link: "btn-link",
        neutral: "btn-neutral",
        outline: "btn-outline"
      }.freeze

      SIZES = {
        xs: "btn-xs",
        sm: "btn-sm",
        md: "",
        lg: "btn-lg",
        xl: "btn-xl"
      }.freeze

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # rubocop:disable Metrics/ParameterLists
      def initialize(name: nil, variant: nil, size: nil, icon_name: nil, type: :button,
                     disabled: false, loading: false, **options)
        @name = name
        @variant = variant&.to_sym
        @size = size&.to_sym
        @icon_name = icon_name
        @type = type
        @disabled = disabled
        @loading = loading
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def button_classes
        class_names(
          "btn",
          VARIANTS[@variant],
          SIZES[@size],
          "btn-disabled" => @disabled,
          "loading loading-spinner" => @loading
        )
      end

      def button_attributes
        @options.merge(
          class: class_names(button_classes, @options[:class]),
          type: @type,
          disabled: @disabled || nil
        ).compact
      end
    end
  end
end
