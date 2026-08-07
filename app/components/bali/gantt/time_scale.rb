# frozen_string_literal: true

module Bali
  module Gantt
    # What the server still decides about the Gantt's time axis (#704, trimmed
    # by #970): which zoom the island opens at.
    #
    # The px/day densities, the tick and band segments, bar geometry and the
    # today marker all lived here to paint the `:static` board. That board is
    # gone and the island computes every pixel itself (timeScale.js), so what is
    # left is the one decision the client cannot make in time: resolving `:auto`
    # against the window span BEFORE the bundle lands, so the island does not
    # open at its own default (`week`) and rescale the board on mount.
    #
    # The zoom NAMES are still a shared frontier — the island's ZoomControls.jsx
    # offers exactly these three, and `test/bali/components/gantt/time_scale_test.rb`
    # reads the JSX and compares.
    class TimeScale
      # Island parity: ZoomControls.jsx ZOOM_LEVELS keys.
      ZOOMS = %i[day week month].freeze
      DEFAULT_ZOOM = :auto

      # `:auto` picks a density from the window span — the portfolio's "zoom by
      # range" rule, kept because a board that opens at the wrong density is a
      # board the visitor has to fix before reading it.
      AUTO_DAY_MAX_DAYS = 45
      AUTO_WEEK_MAX_DAYS = 400

      attr_reader :starts_on, :ends_on, :zoom

      # `zoom` usually arrives from a query param, so unknown values normalize to
      # `:auto` instead of raising — user input is not a programmer error.
      def initialize(starts_on:, ends_on:, zoom: DEFAULT_ZOOM)
        @starts_on = starts_on
        @ends_on = ends_on && starts_on ? [ ends_on, starts_on ].max : ends_on
        @zoom = normalize_zoom(zoom)
      end

      def valid? = starts_on.present? && ends_on.present?

      # The zoom actually in effect (`:auto` resolved to a concrete unit). This
      # is what rides to the island as `initial_zoom`.
      def resolved_zoom
        @resolved_zoom ||= zoom == :auto ? auto_zoom : zoom
      end

      private

      def normalize_zoom(value)
        candidate = value.presence&.to_sym
        ZOOMS.include?(candidate) ? candidate : :auto
      end

      def auto_zoom
        return :week unless valid?

        span = (ends_on - starts_on).to_i + 1
        if span <= AUTO_DAY_MAX_DAYS then :day
        elsif span <= AUTO_WEEK_MAX_DAYS then :week
        else :month
        end
      end
    end
  end
end
