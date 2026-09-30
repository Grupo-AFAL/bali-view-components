# frozen_string_literal: true

require "test_helper"

class BaliIsoDateTest < ActiveSupport::TestCase
  def test_parses_a_calendar_date
    assert_equal Date.new(2026, 9, 10), Bali::IsoDate.parse("2026-09-10")
  end

  def test_a_date_round_trips
    assert_equal Date.new(2026, 9, 10), Bali::IsoDate.parse(Date.new(2026, 9, 10))
  end

  # Every one of these is a date to `Date.iso8601`, measured on Ruby 4.0.1 (#1211). None of
  # them is the YYYY-MM-DD a caller asked for.
  def test_rejects_what_date_iso8601_accepts_but_nobody_sent
    {
      "2026-09" => "invents the day",
      "--09-10" => "invents the current year",
      "2026-253" => "ordinal",
      "20260910" => "basic format",
      "2026-W37-4" => "ISO week",
      "2026-09-10T23:59:00-07:00" => "drops the time"
    }.each do |text, why|
      assert_nil Bali::IsoDate.parse(text), "#{text.inspect} (#{why})"
    end
  end

  def test_rejects_an_impossible_calendar_date
    assert_nil Bali::IsoDate.parse("2026-02-31")
  end

  # `?date[]=x` and `?date[a]=x` reach a controller as an Array and a Hash.
  def test_rejects_what_is_not_text_without_raising
    [ nil, "", [ "2026-09-10" ], { "a" => "2026-09-10" }, 20_260_910 ].each do |value|
      assert_nil Bali::IsoDate.parse(value), value.inspect
    end
  end

  def test_rejects_long_input_without_raising
    assert_nil Bali::IsoDate.parse("2026-09-10#{'0' * 200}")
  end
end
