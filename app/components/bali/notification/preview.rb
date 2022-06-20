# frozen_string_literals: true

module Bali
  module Notification
    class Preview < ApplicationViewComponentPreview
      # System notification
      # -------------------
      # Default system notification with success type.
      # @param delay number
      # @param fixed toggle
      # @param type [Symbol] select [primary, success, info, warning, danger, link]
      def default(delay: 3000, fixed: true, type: :success)
        render Notification::Component.new(type: type, delay: delay, fixed: fixed) do
          tag.h1 'This is a success notification, Yay!'
        end
      end
    end
  end
end