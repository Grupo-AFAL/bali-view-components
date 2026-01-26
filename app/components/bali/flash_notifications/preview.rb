# frozen_string_literal: true

module Bali
  module FlashNotifications
    class Preview < ApplicationViewComponentPreview
      # Shows a success notification (notice)
      # @param notice text "Success message to display"
      def notice(notice: 'Your changes have been saved successfully!')
        render Bali::FlashNotifications::Component.new(
          notice: notice.presence
        )
      end

      # Shows an error/warning notification (alert)
      # @param alert text "Error/warning message to display"
      def alert(alert: 'Something went wrong. Please try again.')
        render Bali::FlashNotifications::Component.new(
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
