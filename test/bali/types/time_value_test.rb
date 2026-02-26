# frozen_string_literal: true

require "test_helper"

class BaliTypesTimeValueTest < ActiveSupport::TestCase
  def setup
    @subject = Bali::Types::TimeValue.new
  end

  # integration

  def test_integration_with_a_model_casts_a_time_value_from_integer_to_a_date_string
    workout = Workout.new(workout_start_at: 3600)
    assert_equal(Time.zone.parse("#{Date.current} 01:00:00"), workout.workout_start_at)
  end

  def test_integration_with_a_model_serializes_a_date_string_to_a_number_in_seconds
    workout = Workout.create(workout_start_at: "#{Date.current} 01:00:00")
    stored_value = workout.read_attribute_before_type_cast(:workout_start_at)
    assert_equal(3600, stored_value)
  end

  # cast

  def test_cast_returns_nil_if_value_is_blank
    assert_nil(@subject.cast(""))
  end

  def test_cast_returns_value_if_is_a_date_string
    date_string = "#{Date.current} 00:00:00"
    assert_equal(Time.zone.parse(date_string), @subject.cast(date_string))
  end

  def test_cast_handles_datetimes_without_seconds
    date_string = "#{Date.current} 00:00"
    assert_equal(Time.zone.parse(date_string), @subject.cast(date_string))
  end

  def test_cast_converts_a_integer_to_a_date_string
    assert_equal(Time.zone.parse("#{Date.current} 01:00:00"), @subject.cast(3_600))
    assert_equal(Time.zone.parse("#{Date.current} 01:01:01"), @subject.cast(3_661))
    assert_equal(Time.zone.parse("#{Date.current} 10:10:10"), @subject.cast(36_610))
  end

  # serialize

  def test_serialize_returns_value_if_is_blank
    assert_equal("", @subject.serialize(""))
  end

  def test_serialize_returns_value_if_is_numeric
    assert_equal(3600, @subject.serialize(3600))
  end

  def test_serialize_converts_a_date_string_to_an_integer
    assert_equal(3_600, @subject.serialize("#{Date.current} 01:00:00"))
    assert_equal(3_661, @subject.serialize("#{Date.current} 01:01:01"))
    assert_equal(36_610, @subject.serialize("#{Date.current} 10:10:10"))
  end

  def test_serialize_converts_a_time_object_to_an_integer
    assert_equal(3_600, @subject.serialize(Time.zone.parse("#{Date.current} 01:00:00")))
    assert_equal(3_661, @subject.serialize(Time.zone.parse("#{Date.current} 01:01:01")))
    assert_equal(36_610, @subject.serialize(Time.zone.parse("#{Date.current} 10:10:10")))
  end
end
