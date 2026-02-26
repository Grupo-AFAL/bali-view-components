# frozen_string_literal: true

require "test_helper"

class ModelWithDateRangeAttribute
  include ActiveModel::Attributes
  include Bali::Concerns::DateRangeAttribute

  date_range_attribute :date_range
end

Workout.class_eval do
  include Bali::Concerns::DateRangeAttribute

  date_range_attribute :working_period, start_attribute: :workout_start_at,
                                        end_attribute: :workout_end_at
  date_range_attribute :available_period, start_attribute: :available_from,
                                          end_attribute: :available_to
end

class Bali_Concerns_DateRangeAttribute_ActiveModelTest < ActiveSupport::TestCase
  def setup
    @model = ModelWithDateRangeAttribute.new
  end

  def test_date_range_returns_assigned_range
    @model.date_range = Time.zone.now.all_day
    assert_equal(Time.zone.now.all_day, @model.date_range)
  end

  def test_date_range_setter_with_range_object
    @model.date_range = Time.zone.now.all_day
    assert_equal(Time.zone.now.all_day, @model.date_range)
  end

  def test_date_range_setter_with_valid_date_range_string
    range = Time.zone.local(2023, 3, 1)..Time.zone.local(2023, 3, 10).end_of_day
    @model.date_range = "2023-03-01 to 2023-03-10"
    assert_equal(range, @model.date_range)
  end

  def test_date_range_setter_with_single_day_string
    range = Time.zone.local(2023, 3, 1)..Time.zone.local(2023, 3, 1).end_of_day
    @model.date_range = "2023-03-01"
    assert_equal(range, @model.date_range)
  end

  def test_date_range_setter_with_empty_string
    @model.date_range = ""
    assert_nil(@model.date_range)
  end
end

class Bali_Concerns_DateRangeAttribute_WorkingPeriodTest < ActiveSupport::TestCase
  def setup
    @model = Workout.new
  end

  # working_period (DB columns)

  def test_working_period_returns_assigned_range
    @model.working_period = Time.zone.now.all_day
    assert_equal(Time.zone.now.all_day, @model.working_period)
    assert_equal(Time.zone.now.beginning_of_day, @model.workout_start_at)
    assert_equal(Time.zone.now.end_of_day, @model.workout_end_at)
  end

  def test_working_period_setter_with_range_object
    @model.working_period = Time.zone.now.all_day
    assert_equal(Time.zone.now.all_day, @model.working_period)
    assert_equal(Time.zone.now.beginning_of_day, @model.workout_start_at)
    assert_equal(Time.zone.now.end_of_day, @model.workout_end_at)
  end

  def test_working_period_setter_with_valid_date_range_string
    range_start = Time.zone.local(2023, 3, 1)
    range_end = Time.zone.local(2023, 3, 10).end_of_day
    @model.working_period = "2023-03-01 to 2023-03-10"
    assert_equal(range_start..range_end, @model.working_period)
    assert_equal(range_start, @model.workout_start_at)
    assert_equal(range_end, @model.workout_end_at)
  end

  def test_working_period_setter_with_single_day_string
    range_start = Time.zone.local(2023, 3, 1)
    range_end = Time.zone.local(2023, 3, 1).end_of_day
    @model.working_period = "2023-03-01"
    assert_equal(range_start..range_end, @model.working_period)
    assert_equal(range_start, @model.workout_start_at)
    assert_equal(range_end, @model.workout_end_at)
  end

  def test_working_period_setter_with_empty_string
    @model.working_period = ""
    assert_nil(@model.working_period)
    assert_nil(@model.workout_start_at)
    assert_nil(@model.workout_end_at)
  end

  # available_period (non-DB columns)

  def test_available_period_returns_assigned_range
    @model.available_period = Time.zone.now.all_day
    assert_equal(Time.zone.now.all_day, @model.available_period)
    assert_equal(Time.zone.now.beginning_of_day, @model.available_from)
    assert_equal(Time.zone.now.end_of_day, @model.available_to)
  end

  def test_available_period_setter_with_range_object
    @model.available_period = Time.zone.now.all_day
    assert_equal(Time.zone.now.all_day, @model.available_period)
    assert_equal(Time.zone.now.beginning_of_day, @model.available_from)
    assert_equal(Time.zone.now.end_of_day, @model.available_to)
  end

  def test_available_period_setter_with_valid_date_range_string
    range_start = Time.zone.local(2023, 3, 1)
    range_end = Time.zone.local(2023, 3, 10).end_of_day
    @model.available_period = "2023-03-01 to 2023-03-10"
    assert_equal(range_start..range_end, @model.available_period)
    assert_equal(range_start, @model.available_from)
    assert_equal(range_end, @model.available_to)
  end

  def test_available_period_setter_with_single_day_string
    range_start = Time.zone.local(2023, 3, 1)
    range_end = Time.zone.local(2023, 3, 1).end_of_day
    @model.available_period = "2023-03-01"
    assert_equal(range_start..range_end, @model.available_period)
    assert_equal(range_start, @model.available_from)
    assert_equal(range_end, @model.available_to)
  end

  def test_available_period_setter_with_empty_string
    @model.available_period = ""
    assert_nil(@model.available_period)
    assert_nil(@model.available_from)
    assert_nil(@model.available_to)
  end
end
