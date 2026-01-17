# frozen_string_literal: true

module Bali
  module FlashNotifications
    class Preview < ApplicationViewComponentPreview
      # @param notice text "Success message to display"
      # @param alert text "Error/warning message to display"
      def default(notice: nil, alert: nil)
        render Bali::FlashNotifications::Component.new(
          notice: notice.presence,
          alert: alert.presence
        )
      end

      # Demonstrates both flash types appearing simultaneously
      def both
        render Bali::FlashNotifications::Component.new(
          notice: 'Operation completed successfully',
          alert: 'But there was a warning to review'
        )
      end
    end
  end
end
