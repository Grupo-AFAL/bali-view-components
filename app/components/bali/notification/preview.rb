# frozen_string_literals: true

module Bali
  module Notification
    class Preview < ApplicationViewComponentPreview
      # System notification
      # -------------------
      # Default system notification with success type.
      # @param type [Symbol] select [primary, success, info, warning, danger, link]
      # @param delay number
      # @param fixed toggle
      # @param dismissible toggle
      def default(delay: 3000, fixed: true, type: :success, dismissible: false)
        render Notification::Component.new(
          type: type, delay: delay, fixed: fixed, dismissible: dismissible) do
          tag.h1 'This is a notification, Yay!, Oh no!'
        end
      end
    end
  end
end