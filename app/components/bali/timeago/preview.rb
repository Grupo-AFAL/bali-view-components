# frozen_string_literal: true

module Bali
  module Timeago
    class Preview < ApplicationViewComponentPreview
      # Timeago
      # ----------------------
      # Displays the distance between the given date and now in words
      #
      # @param add_suffix [Boolean] toggle
      # @param include_seconds [Boolean] toggle
      # @param refresh_interval number
      def default(add_suffix: false, include_seconds: true, refresh_interval: nil)
        render Bali::Timeago::Component.new(
          1.second.ago,
          add_suffix: add_suffix,
          include_seconds: include_seconds,
          refresh_interval: refresh_interval
        )
      end
    end
  end
end
