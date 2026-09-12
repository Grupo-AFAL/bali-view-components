# frozen_string_literal: true

require "test_helper"

# This type is shared surface: the FilterForm applies date_range filters through it AND the
# form builder round-trips `f.date_field(mode: "range")` through it. Presets had to be
# strictly additive, so half of this file is about what did NOT change.
class BaliTypesDateRangeValueTest < ActiveSupport::TestCase
  def setup
    @type = Bali::Types::DateRangeValue.new
  end

  # presets

  def test_cast_resolves_today_against_time_zone_at_query_time
    travel_to Time.zone.parse("2026-08-06 15:30:00") do
      range = @type.cast("today")

      assert_equal Time.zone.parse("2026-08-06 00:00:00"), range.first
      assert_equal Time.zone.parse("2026-08-06").end_of_day, range.last
    end
  end

  def test_cast_resolves_this_week_from_monday_to_sunday
    travel_to Time.zone.parse("2026-08-06 15:30:00") do # a Thursday
      range = @type.cast("this_week")

      assert_equal Time.zone.parse("2026-08-03 00:00:00"), range.first
      assert_equal Time.zone.parse("2026-08-09").end_of_day, range.last
    end
  end

  def test_cast_resolves_this_month_to_the_whole_calendar_month
    travel_to Time.zone.parse("2026-08-06 15:30:00") do
      range = @type.cast("this_month")

      assert_equal Time.zone.parse("2026-08-01 00:00:00"), range.first
      assert_equal Time.zone.parse("2026-08-31").end_of_day, range.last
    end
  end

  def test_cast_resolves_trailing_windows_inclusive_of_today
    travel_to Time.zone.parse("2026-08-06 15:30:00") do
      assert_equal Time.zone.parse("2026-07-31 00:00:00"), @type.cast("last_7_days").first
      assert_equal Time.zone.parse("2026-08-06").end_of_day, @type.cast("last_7_days").last

      assert_equal Time.zone.parse("2026-07-08 00:00:00"), @type.cast("last_30_days").first
      assert_equal Time.zone.parse("2026-08-06").end_of_day, @type.cast("last_30_days").last
    end
  end

  # The point of a token over two dates: the SAME stored value means something different
  # next month, which is what a saved view or a persisted filter is expected to do.
  def test_the_same_token_resolves_to_a_different_range_on_a_different_day
    august = travel_to(Time.zone.parse("2026-08-06")) { @type.cast("this_month") }
    september = travel_to(Time.zone.parse("2026-09-14")) { @type.cast("this_month") }

    refute_equal august, september
    assert_equal Time.zone.parse("2026-09-01 00:00:00"), september.first
  end

  # A Date range would look right and filter wrong: Rails casts both ends to midnight, so
  # `where(created_at: date_range)` would drop everything recorded on the last day.
  def test_cast_returns_times_so_the_last_day_is_not_cut_off
    range = travel_to(Time.zone.parse("2026-08-06")) { @type.cast("this_month") }

    assert_kind_of ActiveSupport::TimeWithZone, range.first
    assert_kind_of ActiveSupport::TimeWithZone, range.last
    assert_equal 23, range.last.hour
  end

  def test_cast_leaves_an_unknown_token_to_the_ordinary_parsing_path
    assert_raises(NoMethodError) { @type.cast("next_century") }
  end

  # additivity — everything below is the behaviour presets had to leave alone

  def test_cast_still_parses_an_explicit_stringified_range
    range = @type.cast("2026-01-01..2026-03-31")

    assert_equal Time.zone.parse("2026-01-01"), range.first
    assert_equal Time.zone.parse("2026-03-31"), range.last
  end

  def test_cast_still_parses_a_beginless_and_an_endless_range
    assert_nil @type.cast("..2026-03-31").begin
    assert_equal Time.zone.parse("2026-03-31"), @type.cast("..2026-03-31").end

    assert_equal Time.zone.parse("2026-01-01"), @type.cast("2026-01-01..").begin
    assert_nil @type.cast("2026-01-01..").end
  end

  def test_cast_still_parses_the_localized_separator_form
    range = @type.cast("2026-01-01 to 2026-03-31")

    assert_equal Time.zone.parse("2026-01-01").beginning_of_day, range.first
    assert_equal Time.zone.parse("2026-03-31").end_of_day, range.last
  end

  def test_cast_still_widens_a_single_date_to_that_whole_day
    range = @type.cast("2026-01-01")

    assert_equal Time.zone.parse("2026-01-01").beginning_of_day, range.first
    assert_equal Time.zone.parse("2026-01-01").end_of_day, range.last
  end

  def test_cast_still_passes_blanks_and_non_strings_through
    assert_nil @type.cast("")
    assert_nil @type.cast(nil)

    already_a_range = Time.zone.parse("2026-01-01")..Time.zone.parse("2026-01-31")
    assert_equal already_a_range, @type.cast(already_a_range)
  end
end
