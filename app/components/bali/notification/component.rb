# frozen_string_literal: true

module Bali
  module Notification
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'notification-component alert'
      SHADOW_CLASSES = 'shadow-[0px_3px_18px_rgba(0,0,0,0.1),0_0_0_1px_rgba(0,0,0,0.03)]'
      UNCLOSABLE_CLASSES = '[&.is-unclosable_.btn-circle]:hidden ' \
                           '[&.is-unclosable_.notification-content-component]:mr-0'

      TYPES = {
        success: 'alert-success',
        info: 'alert-info',
        warning: 'alert-warning',
        error: 'alert-error',
        danger: 'alert-error',
        primary: 'alert-info'
      }.freeze

      def initialize(type: :success, delay: 3000, fixed: true, dismiss: true, **options)
        @type = type&.to_sym
        @delay = delay
        @fixed = fixed
        @dismiss = dismiss
        @options = options
      end

      def alert_classes
        class_names(
          BASE_CLASSES,
          SHADOW_CLASSES,
          UNCLOSABLE_CLASSES,
          type_class,
          fixed_classes,
          options[:class]
        )
      end

      def stimulus_attributes
        {
          controller: 'notification',
          'notification-delay-value': delay,
          'notification-dismiss-value': dismiss,
          'turbo-cache': false
        }
      end

      def close_button_label
        t('.close')
      end

      private

      attr_reader :type, :delay, :fixed, :dismiss, :options

      def type_class
        TYPES.fetch(type, TYPES[:success])
      end

      def fixed_classes
        return unless fixed

        class_names(
          'fixed top-[4.25rem] right-4 z-[101]',
          Bali.native_app && 'top-4 left-1/2 right-auto -translate-x-1/2 w-full'
        )
      end
    end
  end
end
