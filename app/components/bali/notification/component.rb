# frozen_string_literal: true

module Bali
  module Notification
    class Component < ApplicationViewComponent
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
          'notification-component',
          'alert',
          'shadow-[0px_3px_18px_rgba(0,0,0,0.1),0_0_0_1px_rgba(0,0,0,0.03)]',
          '[&.is-unclosable_.btn-circle]:hidden',
          '[&.is-unclosable_.notification-content-component]:mr-0',
          TYPES[@type],
          @fixed && 'fixed top-[4.25rem] right-4 z-[101]',
          @fixed && Bali.native_app && 'top-4 left-1/2 right-auto -translate-x-1/2 w-full',
          @options[:class]
        )
      end

      def stimulus_attributes
        {
          controller: 'notification',
          'notification-delay-value': @delay,
          'notification-dismiss-value': @dismiss,
          'turbo-cache': false
        }
      end
    end
  end
end
