# frozen_string_literal: true

require "test_helper"

class BaliWidgetGoalTest < ActiveSupport::TestCase
  # This object says what the goal IS; `Bali::Gauge::Component` owns the
  # arithmetic and the clamping, and its own test covers them — a value past
  # `max`, a `max` of zero, and the accessible value staying true. Duplicating
  # that here was two sets of rounding rules with one caller between them.
  def test_max_defaults_to_a_hundred_so_a_bare_percentage_works
    gauge = Bali::Widget::Goal.new(value: 42)

    assert_equal 42, gauge.value
    assert_equal 100, gauge.max
    assert_nil gauge.label
  end

  def test_carries_the_label_the_ring_prints_under_its_figure
    assert_equal "of 10", Bali::Widget::Goal.new(value: 7, max: 10, label: "of 10").label
  end
end
