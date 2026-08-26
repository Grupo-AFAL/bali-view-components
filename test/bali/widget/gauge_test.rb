# frozen_string_literal: true

require "test_helper"

class BaliWidgetGaugeTest < ActiveSupport::TestCase
  def test_percentage_of_the_max
    assert_in_delta 70.0, Bali::Widget::Gauge.new(value: 7, max: 10).percentage
  end

  # A gauge past its goal is a real state — 11 of 10 shifts covered — and the
  # ring has nowhere to draw it. Clamped for display; `value` still reads true.
  def test_percentage_clamps_at_the_ends_without_touching_the_value
    over = Bali::Widget::Gauge.new(value: 11, max: 10)

    assert_in_delta 100.0, over.percentage
    assert_equal 11, over.value
    assert_in_delta 0.0, Bali::Widget::Gauge.new(value: -1, max: 10).percentage
  end

  # A max of zero is "no goal set", not an error, and dividing by it would take
  # the whole dashboard down for one misconfigured widget.
  def test_a_zero_max_reads_as_empty_rather_than_raising
    assert_in_delta 0.0, Bali::Widget::Gauge.new(value: 5, max: 0).percentage
  end

  def test_defaults_max_to_a_hundred_so_a_bare_percentage_works
    assert_in_delta 42.0, Bali::Widget::Gauge.new(value: 42).percentage
  end
end
