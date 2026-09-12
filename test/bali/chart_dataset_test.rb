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
end
