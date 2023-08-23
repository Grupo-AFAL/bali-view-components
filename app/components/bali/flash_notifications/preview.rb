# frozen_string_literal: true

module Bali
  module FlashNotifications
    class Preview < ApplicationViewComponentPreview
      def default
        render Bali::FlashNotifications::Component.new
      end

      def notice
        render Bali::FlashNotifications::Component.new(notice: 'This is a notice')
      end

      def alert
        render Bali::FlashNotifications::Component.new(alert: 'This is an alert')
      end
    end
  end
end
