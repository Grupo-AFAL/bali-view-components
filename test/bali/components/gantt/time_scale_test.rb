# frozen_string_literal: true

require "test_helper"

class BaliGanttTimeScaleTest < ActiveSupport::TestCase
  def scale(starts_on: Date.new(2026, 1, 5), ends_on: Date.new(2026, 3, 20), zoom: :week)
    Bali::Gantt::TimeScale.new(starts_on: starts_on, ends_on: ends_on, zoom: zoom)
  end

  # #970 moved every pixel into the island, so Ruby no longer knows how wide a
  # day is — but it still names the zoom levels, and the name it resolves rides
  # to the island as `initial_zoom`. A level that exists on one side only would
  # make the island open at its own default and rescale the board on mount, so
  # this reads ZoomControls.jsx rather than restating it.
  def test_zoom_levels_match_the_island
    source = Bali::Engine.root.join("app/components/bali/gantt/ZoomControls.jsx").read
    levels = source.scan(/\{\s*key:\s*'(\w+)'/).flatten.map(&:to_sym)

    assert_equal Bali::Gantt::TimeScale::ZOOMS.sort, levels.sort,
                 "ZoomControls.jsx and TimeScale disagree about which zoom levels exist"
  end

  def test_unknown_zoom_values_normalize_to_auto
    assert_equal :auto, scale(zoom: "huge").zoom
    assert_equal :auto, scale(zoom: nil).zoom
  end

  def test_an_explicit_zoom_is_what_resolves
    assert_equal :month, scale(zoom: :month).resolved_zoom
    assert_equal :day, scale(zoom: "day").resolved_zoom
  end

  def test_auto_zoom_picks_density_from_the_window_span
    assert_equal :day, scale(ends_on: Date.new(2026, 1, 31), zoom: :auto).resolved_zoom
    assert_equal :week, scale(ends_on: Date.new(2026, 9, 30), zoom: :auto).resolved_zoom
    assert_equal :month, scale(ends_on: Date.new(2029, 1, 5), zoom: :auto).resolved_zoom
  end

  # A window whose end precedes its start is data the host got wrong; clamping
  # keeps `:auto` from reading a negative span and picking `:month` for a board
  # that spans a day.
  def test_an_inverted_window_clamps_to_its_start
    subject = scale(starts_on: Date.new(2026, 3, 20), ends_on: Date.new(2026, 1, 5), zoom: :auto)

    assert_equal Date.new(2026, 3, 20), subject.ends_on
    assert_equal :day, subject.resolved_zoom
  end

  # An empty document has no window at all. `:auto` still has to answer with a
  # level the island understands, and `week` is the island's own default.
  def test_without_dates_auto_falls_back_to_the_islands_default
    subject = Bali::Gantt::TimeScale.new(starts_on: nil, ends_on: nil)

    refute_predicate subject, :valid?
    assert_equal :week, subject.resolved_zoom
  end
end
