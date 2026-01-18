# frozen_string_literal: true

module Bali
  module Timeago
    class Preview < ApplicationViewComponentPreview
      # Timeago
      # ----------------------
      # Displays relative time ("5 minutes ago", "2 hours ago") that updates dynamically.
      # Uses date-fns for localized formatting.
      #
      # @param add_suffix toggle "Show suffix like 'ago'"
      # @param include_seconds toggle "Include seconds in output"
      # @param refresh_interval number "Auto-refresh interval in milliseconds (0 to disable)"
      def default(add_suffix: false, include_seconds: true, refresh_interval: 0)
        render Bali::Timeago::Component.new(
          30.seconds.ago,
          add_suffix: add_suffix,
          include_seconds: include_seconds,
          refresh_interval: refresh_interval.positive? ? refresh_interval : nil
        )
      end

      # Time Ranges
      # ----------------------
      # Examples of different time distances to show the formatting variety.
      def time_ranges
        render_with_template
      end

      # Auto-Refresh
      # ----------------------
      # The refresh_interval param enables automatic updates (in milliseconds).
      # Useful for showing "live" timestamps like "just now" or "1 minute ago".
      def auto_refresh
        render Bali::Timeago::Component.new(
          Time.current,
          add_suffix: true,
          refresh_interval: 1000
        )
      end
    end
  end
end
