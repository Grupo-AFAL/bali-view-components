# frozen_string_literal: true

module Bali
  module Notification
    class Component < ApplicationViewComponent
      attr_reader :options

      # Notification Component with different type of notification.
      #
      # @param [Symbol] type This adds a class for the notification: :success, :danger
      # @param [Integer] delay How long the notification will be shown.
      # @param [Boolean] fixed This add fixed position to the component.
      # @param [Boolean] dismiss This validates if removes or not the component after delay.
      # @param [Hash] options This adds a custom attributes to the component.
      def initialize(type: :success, delay: 3000, fixed: true, dismiss: true, **options)
        @options = prepend_class_name(options, "notification-component notification is-#{type}")
        @options = prepend_class_name(@options, 'fixed') if fixed
        @options = prepend_class_name(@options, 'native-app') if Bali.native_app
        @options = prepend_controller(@options, 'notification')
        @options = prepend_data_attribute(@options, 'notification-delay-value', delay)
        @options = prepend_data_attribute(@options, 'notification-dismiss-value', dismiss)
        @options = prepend_data_attribute(@options, 'turbo-cache', false)
      end
    end
  end
end
