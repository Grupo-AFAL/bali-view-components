# frozen_string_literal: true

module Bali
  module Notification
    class Preview < ApplicationViewComponentPreview
      # @param type [Symbol] select [success, info, warning, error]
      # @param style [Symbol] select [~, soft, outline, dash]
      # @param delay number
      # @param fixed toggle
      # @param dismiss toggle
      def default(delay: 3000, fixed: true, type: :success, style: nil, dismiss: false)
        render Notification::Component.new(type: type, delay: delay, fixed: fixed,
                                           dismiss: dismiss, style: style) do
          'This is a notification message!'
        end
      end

      # @label All Types & Styles
      def all_types
        render_with_template
      end
    end
  end
end
