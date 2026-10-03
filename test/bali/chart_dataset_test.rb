# frozen_string_literal: true

require "test_helper"

class BaliChartDatasetTest < ActiveSupport::TestCase
  # The white ring separating a point from its own line is a default, not a
  # lock: a caller drawing a hollow marker (transparent fill + colored border,
  # e.g. bali-analytics' k-anonymity suppression mark) needs to pick the ring
  # color, or the mark disappears on a white surface (#1065).
  def test_line_point_border_defaults_stay_white
    result = Bali::Chart::Dataset.new(type: :line, data: [ 1, 2 ]).to_h

    assert_equal "#ffffff", result[:pointBorderColor]
    assert_equal 2, result[:pointBorderWidth]
  end

  def test_line_point_border_color_is_overridable
    result = Bali::Chart::Dataset.new(
      type: :line, data: [ 1, 2 ], pointBorderColor: "rgba(100, 116, 139, 0.90)"
    ).to_h

    assert_equal "rgba(100, 116, 139, 0.90)", result[:pointBorderColor]
  end

  def test_line_point_border_width_is_overridable
    result = Bali::Chart::Dataset.new(type: :line, data: [ 1, 2 ], pointBorderWidth: 3).to_h

    assert_equal 3, result[:pointBorderWidth]
  end

  def test_non_line_point_border_color_passes_through_untouched
    result = Bali::Chart::Dataset.new(
      type: :bar, data: [ 1, 2 ], pointBorderColor: "#123456"
    ).to_h

    assert_equal "#123456", result[:pointBorderColor]
  end

  # Left on the palette's colour, the points and legend swatch would not be the line's.
  def test_line_points_take_the_hosts_border_colour
    assert_equal "#2563eb", theme_line(borderColor: "#2563eb")[:pointBackgroundColor]
  end

  # bali-analytics' suppressed band: a hidden line over a fill, whose legend swatch is
  # its only point.
  def test_line_points_take_the_hosts_fill_before_its_border
    band = theme_line(borderColor: "rgba(0, 0, 0, 0)", backgroundColor: "rgba(148, 163, 184, 0.20)")

    assert_equal "rgba(148, 163, 184, 0.20)", band[:pointBackgroundColor]
  end

  # The same CSS as the border, which chart/index.js resolves in the page's theme.
  def test_line_points_of_a_theme_series_follow_its_border
    line = theme_line

    assert_equal "color-mix(in oklch, var(--color-primary) 80%, transparent)", line[:pointBackgroundColor]
    assert_equal [ line[:pointBackgroundColor] ], line[:borderColor]
  end

  # A series without a border of its own is drawn in the palette's colour, and a fill of its
  # own (an area's tint) does not take its points off the line.
  def test_line_points_of_a_theme_series_ignore_a_fill_of_its_own
    line = theme_line(backgroundColor: "#ff0000")

    assert_equal line[:borderColor].first, line[:pointBackgroundColor]
  end

  private

  # A line as Bali::Chart::Component builds it, its colour handed out from the theme.
  def theme_line(**options)
    Bali::Chart::Dataset.new(type: :line, data: [ 1, 2 ], color: [ Bali::Color.css(:primary) ], **options).to_h
  end
end
