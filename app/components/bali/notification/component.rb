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
          TYPES[@type],
          @fixed && 'fixed top-4 right-4 left-4 md:left-auto md:w-96 z-50',
          Bali.native_app && 'native-app',
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
