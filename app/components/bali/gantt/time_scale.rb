# frozen_string_literal: true

module Bali
  module Gantt
    # Date ↔ pixel geometry for the Gantt (#704). One coordinate system: DAYS.
    #
    # x(date) = days from the window start × px_per_day — the same conversion the
    # React island's timeScale.js uses (dateToX / daysBetween), so phase 2 shares
    # these numbers instead of reimplementing them. The zoom levels carry the
    # island's exact densities (ZoomControls.jsx: day 24, week 8, month 2 px/day).
    #
    # This is also the port of TDFlow::PortfolioGantt's geometry rules, translated
    # into day units: fixed zoom picked by window span (`:auto`), minimum bar
    # width, inclusive end dates, fractional positioning (free with day units —
    # the portfolio's fractional-month formula approximated exactly this) and the
    # today marker. Month columns get their true calendar width (28–31 days), so
    # the grid never drifts.
    #
    # Everything returns plain numbers/hashes for the template to inline in
    # `style=` attributes — computed geometry never goes into interpolated
    # Tailwind classes (v4 purges them; rule inherited from the portfolio view).
    class TimeScale
      # Island parity: ZoomControls.jsx ZOOM_LEVELS.
      PX_PER_DAY = { day: 24, week: 8, month: 2 }.freeze
      ZOOMS = PX_PER_DAY.keys.freeze
      DEFAULT_ZOOM = :auto

      # `:auto` picks a fixed density from the window span — the portfolio's
      # "zoom by range" rule (a read-only board should not need a zoom control).
      AUTO_DAY_MAX_DAYS = 45
      AUTO_WEEK_MAX_DAYS = 400

      MIN_BAR_PX = 6 # a one-day task is still visible (portfolio parity)

      attr_reader :starts_on, :ends_on, :zoom

      # `zoom` usually arrives from a query param, so unknown values normalize to
      # `:auto` instead of raising — user input is not a programmer error.
      def initialize(starts_on:, ends_on:, zoom: DEFAULT_ZOOM)
        @starts_on = starts_on
        @ends_on = ends_on && starts_on ? [ ends_on, starts_on ].max : ends_on
        @zoom = normalize_zoom(zoom)
      end

      def valid? = starts_on.present? && ends_on.present?

      # The zoom actually in effect (`:auto` resolved to a concrete unit).
      def resolved_zoom
        @resolved_zoom ||= if zoom == :auto
                             auto_zoom
        else
                             zoom
        end
      end

      def px_per_day = PX_PER_DAY.fetch(resolved_zoom)

      # X in px of a date, measured from the window start. Same formula as the
      # island's dateToX.
      def x_for(date)
        ((date - starts_on) * px_per_day).to_i
      end

      # Canvas width: the end date is INCLUSIVE, so the axis runs through the
      # last day, not up to its midnight.
      def total_width
        @total_width ||= valid? ? x_for(ends_on + 1) : 0
      end

      # { left:, width: } for a bar, clamped to the canvas so an explicit window
      # narrower than the data cannot paint outside it. End inclusive; minimum
      # width so a one-day bar stays visible.
      def bar_geometry(bar_starts_on, bar_ends_on)
        left = x_for(bar_starts_on).clamp(0, total_width)
        right = x_for(bar_ends_on + 1).clamp(0, total_width)
        { left: left, width: [ right - left, MIN_BAR_PX ].max }
      end

      # Lower header tier: one tick per resolved unit, clipped to the canvas.
      # [{ key:, label:, x:, width: }]
      def ticks
        @ticks ||= case resolved_zoom
        when :day then day_segments
        when :week then week_segments
        else month_segments(with_year: false)
        end
      end

      # Upper header tier for context: months over day/week zoom, years over
      # month zoom — the island's timeBands and the portfolio's year band.
      def bands
        @bands ||= resolved_zoom == :month ? year_segments : month_segments(with_year: true)
      end

      # X of the "today" marker, or nil when today falls outside the window.
      def today_x
        return nil unless valid?
        return nil unless Date.current.between?(starts_on, ends_on)

        x_for(Date.current)
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

      def day_segments
        return [] unless valid?

        (starts_on..ends_on).map do |date|
          { key: date.iso8601, label: date.day.to_s, x: x_for(date), width: px_per_day }
        end
      end

      def week_segments
        segments(step: :week) do |date|
          "#{date.day} #{abbr_month(date)}"
        end
      end

      def month_segments(with_year:)
        segments(step: :month) do |date|
          with_year ? "#{month_name(date)} #{date.year}" : abbr_month(date)
        end
      end

      def year_segments
        segments(step: :year) { |date| date.year.to_s }
      end

      # Walks calendar boundaries from the unit containing the window start,
      # clipping the first and last segments to the canvas — the island's
      # timeTicks/timeBands segStart rule.
      def segments(step:)
        return [] unless valid?

        axis_end = ends_on + 1
        cursor = unit_start(starts_on, step)
        list = []
        while cursor < axis_end
          seg_start = [ cursor, starts_on ].max
          seg_end = [ advance(cursor, step), axis_end ].min
          list << { key: seg_start.iso8601, label: yield(cursor),
                    x: x_for(seg_start), width: (seg_end - seg_start).to_i * px_per_day }
          cursor = advance(cursor, step)
        end
        list
      end

      def unit_start(date, step)
        case step
        when :week then date.beginning_of_week(:monday)
        when :month then date.beginning_of_month
        else date.beginning_of_year
        end
      end

      def advance(date, step)
        case step
        when :week then date + 7
        when :month then date.next_month
        else date.next_year
        end
      end

      def abbr_month(date)
        I18n.t("date.abbr_month_names")[date.month]
      end

      def month_name(date)
        I18n.t("date.month_names")[date.month]
      end
    end
  end
end
