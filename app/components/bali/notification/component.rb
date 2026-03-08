# frozen_string_literal: true

module Bali
  module Notification
    class Component < ApplicationViewComponent
      BASE_CLASSES = "notification-component alert shadow-xl"
      UNCLOSABLE_CLASSES = "[&.is-unclosable_.btn-circle]:hidden " \
                           "[&.is-unclosable_.notification-content-component]:mr-0"

      TYPES = {
        success: "alert-success",
        info: "alert-info",
        warning: "alert-warning",
        error: "alert-error",
        danger: "alert-error",
        primary: "alert-info"
      }.freeze

      ICONS = {
        success: "circle-check",
        info: "info",
        warning: "triangle-alert",
        error: "circle-x",
        danger: "circle-x",
        primary: "info"
      }.freeze

      STYLES = {
        soft: "alert-soft",
        outline: "alert-outline",
        dash: "alert-dash"
      }.freeze

      def initialize(type: :success, delay: 3000, fixed: true, dismiss: true, style: nil, **options)
        @type = type&.to_sym
        @delay = delay
        @fixed = fixed
        @dismiss = dismiss
        @style = style&.to_sym
        @options = options
      end

      def alert_classes
        class_names(
          BASE_CLASSES,
          UNCLOSABLE_CLASSES,
          type_class,
          style_class,
          fixed_classes,
          options[:class]
        )
      end

      def stimulus_attributes
        {
          controller: "notification",
          'notification-delay-value': delay,
          'notification-dismiss-value': dismiss,
          'turbo-cache': false
        }
      end

      def type_icon
        ICONS.fetch(type, ICONS[:success])
      end

      def close_button_label
        t(".close")
      end

      def aria_role
        type == :error || type == :danger ? "alert" : "status"
      end

      private

      attr_reader :type, :delay, :fixed, :dismiss, :style, :options

      def type_class
        TYPES.fetch(type, TYPES[:success])
      end

      def style_class
        STYLES[style]
      end

      def fixed_classes
        return unless fixed

        class_names(
          "fixed bottom-4 right-4 z-[101]",
          Bali.native_app && "bottom-4 left-1/2 right-auto -translate-x-1/2 w-full"
        )
      end
    end
  end
end
