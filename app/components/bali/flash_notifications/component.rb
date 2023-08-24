# frozen_string_literal: true

module Bali
  module FlashNotifications
    class Component < ApplicationViewComponent
      attr_reader :notice, :alert

      def initialize(notice: nil, alert: nil)
        @notice = notice
        @alert = alert
      end
    end
  end
end
