# frozen_string_literal: true

require "test_helper"

class BaliGanttTimeScaleTest < ActiveSupport::TestCase
  def scale(starts_on: Date.new(2026, 1, 5), ends_on: Date.new(2026, 3, 20), zoom: :week)
    Bali::Gantt::TimeScale.new(starts_on: starts_on, ends_on: ends_on, zoom: zoom)
  end

  # The anti-flicker promise of `mode: :interactive` (#719) rests entirely on
  # both renderers agreeing about px/day: a bar that is 288px server-side has to
  # be 288px once React takes over. That agreement used to be held together by a
  # comment, which a one-character edit in the JSX could break in silence — so
  # this reads ZoomControls.jsx and compares the real numbers.
  def test_px_per_day_matches_the_island_zoom_levels
    source = Bali::Engine.root.join("app/components/bali/gantt/ZoomControls.jsx").read
    levels = source.scan(/\{\s*key:\s*'(\w+)',\s*pxPerDay:\s*(\d+)/)
                   .to_h { |key, px| [ key.to_sym, px.to_i ] }

    assert_equal Bali::Gantt::TimeScale::PX_PER_DAY.keys.sort, levels.keys.sort,
                 "ZoomControls.jsx and TimeScale disagree about which zoom levels exist"
    levels.each do |key, px_per_day|
      assert_equal px_per_day, scale(zoom: key).px_per_day,
                   "zoom #{key}: the island draws #{px_per_day} px/day and :static would not"
    end
  end

  def test_unknown_zoom_values_normalize_to_auto
    assert_equal :auto, scale(zoom: "huge").zoom
    assert_equal :auto, scale(zoom: nil).zoom
  end

  def test_auto_zoom_picks_density_from_the_window_span
    assert_equal :day, scale(ends_on: Date.new(2026, 1, 31), zoom: :auto).resolved_zoom
    assert_equal :week, scale(ends_on: Date.new(2026, 9, 30), zoom: :auto).resolved_zoom
    assert_equal :month, scale(ends_on: Date.new(2029, 1, 5), zoom: :auto).resolved_zoom
  end

  def test_x_for_is_days_from_window_start_times_density
    subject = scale(zoom: :week)

    assert_equal 0, subject.x_for(Date.new(2026, 1, 5))
    assert_equal 8 * 10, subject.x_for(Date.new(2026, 1, 15))
  end

  def test_total_width_includes_the_final_day
    subject = scale(starts_on: Date.new(2026, 1, 5), ends_on: Date.new(2026, 1, 9), zoom: :day)

    assert_equal 24 * 5, subject.total_width
  end

  def test_bar_geometry_is_end_inclusive_with_a_minimum_width
    subject = scale(zoom: :day)

    one_day = subject.bar_geometry(Date.new(2026, 1, 6), Date.new(2026, 1, 6))
    assert_equal({ left: 24, width: 24 }, one_day)

    thin = scale(zoom: :month).bar_geometry(Date.new(2026, 1, 6), Date.new(2026, 1, 6))
    assert_equal Bali::Gantt::TimeScale::MIN_BAR_PX, thin[:width]
  end

  def test_bar_geometry_clamps_to_the_canvas
    subject = scale(starts_on: Date.new(2026, 2, 1), ends_on: Date.new(2026, 2, 28), zoom: :day)

    geometry = subject.bar_geometry(Date.new(2026, 1, 1), Date.new(2026, 3, 15))

    assert_equal 0, geometry[:left]
    assert_equal subject.total_width, geometry[:width]
  end

  def test_month_ticks_use_true_calendar_widths
    subject = scale(starts_on: Date.new(2026, 1, 10), ends_on: Date.new(2026, 3, 10), zoom: :month)
    ticks = subject.ticks

    assert_equal 3, ticks.size
    # First segment clips at the window start (Jan 10 → Feb 1 = 22 days).
    assert_equal 0, ticks.first[:x]
    assert_equal 22 * 2, ticks.first[:width]
    # February renders its true 28-day width.
    assert_equal 28 * 2, ticks.second[:width]
    # Last segment clips at the inclusive window end (Mar 1 → Mar 11 = 10 days).
    assert_equal 10 * 2, ticks.third[:width]
  end

  def test_week_ticks_start_on_monday_and_clip_at_the_window
    subject = scale(starts_on: Date.new(2026, 1, 7), ends_on: Date.new(2026, 1, 27), zoom: :week)
    ticks = subject.ticks

    # 2026-01-07 is a Wednesday; the first segment runs Wed→Mon (5 days).
    assert_equal 0, ticks.first[:x]
    assert_equal 5 * 8, ticks.first[:width]
    assert_equal 7 * 8, ticks.second[:width]
  end

  def test_day_ticks_enumerate_days
    subject = scale(starts_on: Date.new(2026, 1, 5), ends_on: Date.new(2026, 1, 7), zoom: :day)

    assert_equal %w[5 6 7], subject.ticks.map { |t| t[:label] }
    assert_equal [ 0, 24, 48 ], subject.ticks.map { |t| t[:x] }
  end

  def test_bands_are_months_over_day_and_week_zoom_and_years_over_month_zoom
    weekly = scale(starts_on: Date.new(2026, 1, 5), ends_on: Date.new(2026, 2, 10), zoom: :week)
    assert_equal 2, weekly.bands.size
    assert_match(/January/, weekly.bands.first[:label])

    monthly = scale(starts_on: Date.new(2025, 11, 1), ends_on: Date.new(2026, 2, 1), zoom: :month)
    assert_equal %w[2025 2026], monthly.bands.map { |b| b[:label] }
  end

  def test_today_marker_only_inside_the_window
    inside = scale(starts_on: Date.current - 10, ends_on: Date.current + 10, zoom: :day)
    assert_equal 10 * 24, inside.today_x

    outside = scale(starts_on: Date.current + 5, ends_on: Date.current + 15, zoom: :day)
    assert_nil outside.today_x
  end

  def test_invalid_without_dates
    subject = Bali::Gantt::TimeScale.new(starts_on: nil, ends_on: nil)

    refute_predicate subject, :valid?
    assert_equal 0, subject.total_width
    assert_empty subject.ticks
    assert_empty subject.bands
    assert_nil subject.today_x
  end
end
