# frozen_string_literal: true

require "test_helper"

class BaliWidgetTrendTest < ActiveSupport::TestCase
  def test_direction_is_inferred_from_the_sign_of_the_delta
    assert_equal :up, Bali::Widget::Trend.new(delta: 12).direction
    assert_equal :down, Bali::Widget::Trend.new(delta: -12).direction
  end

  def test_an_explicit_direction_wins_over_the_inferred_one
    trend = Bali::Widget::Trend.new(delta: 12, direction: :down)

    assert_equal :down, trend.direction
  end

  # THE POINT OF THE WHOLE CLASS. "Up" is not universally good: overdue tasks up
  # 12% and revenue up 12% must not read the same colour, and `direction` alone
  # cannot tell them apart.
  def test_good_compares_direction_against_what_counts_as_good_for_this_widget
    assert_predicate Bali::Widget::Trend.new(delta: 12), :good?
    refute_predicate Bali::Widget::Trend.new(delta: -12), :good?

    assert_predicate Bali::Widget::Trend.new(delta: -12, positive_when: :down), :good?
    refute_predicate Bali::Widget::Trend.new(delta: 12, positive_when: :down), :good?
  end

  def test_flat_is_its_own_state_rather_than_a_weak_up
    trend = Bali::Widget::Trend.new(delta: 0)

    assert_predicate trend, :flat?
    refute_predicate Bali::Widget::Trend.new(delta: 1), :flat?
  end

  def test_carries_the_period_it_compares_against
    assert_equal "vs last week", Bali::Widget::Trend.new(delta: 3, period: "vs last week").period
  end
end
