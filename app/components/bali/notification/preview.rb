# frozen_string_literal: true

module Bali
  module Notification
    class Preview < ApplicationViewComponentPreview
      # @param type [Symbol] select [success, info, warning, error]
      # @param delay number
      # @param fixed toggle
      # @param dismiss toggle
      def default(delay: 3000, fixed: true, type: :success, dismiss: false)
        render Notification::Component.new(type: type, delay: delay, fixed: fixed,
                                           dismiss: dismiss) do
          'This is a notification message!'
        end
      end

      def all_types
        render_with_template
      end
    end
  end
end
