# frozen_string_literal: true

require "test_helper"

class BaliWidgetResultTest < ActiveSupport::TestCase
  def test_defaults_to_an_empty_successful_list
    result = Bali::Widget::Result.new

    assert_equal 0, result.count
    assert_empty result.items
    assert_nil result.view_all_path
    refute_predicate result, :failed?
  end

  # The four fields the size ladder added all default to nil, which is what lets
  # every widget written against the original contract keep rendering: the card
  # omits the regions they would have filled instead of failing to find them.
  def test_the_ladder_fields_default_to_nil_so_todays_widgets_are_unchanged
    result = Bali::Widget::Result.new(count: 3)

    assert_nil result.trend
    assert_nil result.series
    assert_nil result.goal
    assert_equal "3", result.display_value
  end

  # The small card is ~215px wide and renders its value at text-4xl, so a raw
  # 1_234_567 runs straight off the tile.
  def test_display_value_abbreviates_the_count_by_default
    assert_equal "1.2k", Bali::Widget::Result.new(count: 1234).display_value
    assert_equal "1.2M", Bali::Widget::Result.new(count: 1_234_567).display_value
  end

  # A widget whose headline is not a count at all — a percentage, a currency —
  # says so, and nothing tries to abbreviate it.
  def test_an_explicit_display_value_is_left_alone
    assert_equal "72%", Bali::Widget::Result.new(count: 72, display_value: "72%").display_value
  end

  def test_abbreviate_keeps_small_numbers_whole_and_drops_a_trailing_zero
    assert_equal "0", Bali::Widget.abbreviate(0)
    assert_equal "999", Bali::Widget.abbreviate(999)
    assert_equal "1k", Bali::Widget.abbreviate(1000)
    assert_equal "12.3k", Bali::Widget.abbreviate(12_345)
    assert_equal "1B", Bali::Widget.abbreviate(1_000_000_000)
  end

  def test_abbreviate_handles_negatives_and_nil
    assert_equal "-1.2k", Bali::Widget.abbreviate(-1234)
    assert_equal "0", Bali::Widget.abbreviate(nil)
  end

  def test_failed_builds_a_failed_result
    assert_predicate Bali::Widget::Result.failed, :failed?
  end

  def test_row_defaults_subtitle_and_href_to_nil
    row = Bali::Widget::Row.new(title: "Tomatoes")

    assert_equal "Tomatoes", row.title
    assert_nil row.subtitle
    assert_nil row.href
  end

  def test_subtitle_joins_parts_and_drops_blanks
    assert_equal "3 left · Cocina", Bali::Widget.subtitle("3 left", nil, "Cocina", "")
  end

  def test_sizes_are_the_three_bento_sizes
    assert_equal %i[small medium large], Bali::Widget::SIZES
  end
end
