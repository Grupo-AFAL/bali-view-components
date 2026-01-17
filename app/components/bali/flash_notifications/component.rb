# frozen_string_literal: true

module Bali
  module FlashNotifications
    class Component < ApplicationViewComponent
      def initialize(notice: nil, alert: nil)
        @notice = notice
        @alert = alert
      end

      private

      attr_reader :notice, :alert
    end
  end
end
