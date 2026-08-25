# frozen_string_literal: true

require "test_helper"

class BaliWidgetResultTest < ActiveSupport::TestCase
  def test_defaults_to_an_empty_successful_list
    result = Bali::Widget::Result.new

    assert_equal 0, result.count
    assert_empty result.items
    assert_nil result.view_all_path
    assert_nil result.payload
    refute_predicate result, :failed?
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

  def test_sizes_are_the_four_bento_sizes
    assert_equal %i[small medium large wide], Bali::Widget::SIZES
  end
end
