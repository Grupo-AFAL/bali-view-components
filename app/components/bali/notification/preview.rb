# frozen_string_literals: true

module Bali
  module Notification
    class Preview < ApplicationViewComponentPreview
      # @!group Notification

      # Success notification
      # -------------------
      # This will add the class `is-success` to the notification.
      def default
        render Notification::Component.new do
          tag.h1 'This is a success notification, Yay!'
        end
      end

      # Danger notification
      # ------------------
      # This will add the class `is-danger` to the notification.
      def danger
        render Notification::Component.new(type: :danger, miliseconds_to_close: 3500 ) do
          tag.h1 'This is a Danger notification, Oh No!'
        end
      end

      # Primary notification
      # ------------------
      # This will add the class `is-primary` to the notification.
      def primary
        render Notification::Component.new(type: :primary, miliseconds_to_close: 4000 ) do
          tag.h1 'This is a alert notification, Should be firts!'
        end
      end

      # Warning notification
      # ------------------
      # This will add the class `is-warning` to the notification.
      def warning
        render Notification::Component.new(type: :warning, miliseconds_to_close: 4500 ) do
          tag.h1 'This is a alert notification, Watch out!'
        end
      end

      # Info notification
      # ------------------
      # This will add the class `is-info` to the notification.
      def info
        render Notification::Component.new(type: :info, miliseconds_to_close: 5000 ) do
          tag.h1 'This is a alert notification, mmm, interesting!'
        end
      end

      # Link notification
      # ------------------
      # This will add the class `is-link` to the notification with 10000 miliseconds to close.
      def link
        render Notification::Component.new(type: :link, miliseconds_to_close: 5500 ) do
          tag.h1 'This is a alert notification, Nice Link!'
        end
      end

      # @!endgroup
    end
  end
end