# frozen_string_literal: true

require "test_helper"

class BaliTypesMonthValueTest < ActiveSupport::TestCase
  def setup
    @type = Bali::Types::MonthValue.new
  end

  # integration

  def test_integration_with_a_model_casts_a_month_value_from_month_string_to_a_date_value
    character = Character.new(birth_month: "2022-08")
    assert_equal(Date.parse("2022-08-01"), character.birth_month)
  end

  def test_integration_with_a_model_assigns_unreadable_input_as_nil
    [ "zzz", [ "2026-09" ] ].each do |value|
      character = Character.new(birth_month: value)
      assert_nil character.birth_month, value.inspect
    end
  end

  # cast

  def test_cast_return_a_nil_if_value_is_blank
    assert_nil(@type.cast(""))
  end

  def test_cast_returns_a_date_object
    assert_equal(Date.parse("2022-08-01"), @type.cast("2022-08"))
  end

  def test_cast_reads_a_full_date
    assert_equal(Date.new(2022, 8, 15), @type.cast("2022-08-15"))
  end

  def test_cast_keeps_a_date
    assert_equal(Date.new(2022, 8, 15), @type.cast(Date.new(2022, 8, 15)))
  end

  # What the PostgreSQL adapter hands over for a timestamp column.
  def test_cast_takes_the_date_of_a_time
    assert_equal(Date.new(2022, 8, 15), @type.cast(Time.utc(2022, 8, 15, 12)))
    assert_equal(Date.new(2022, 8, 15), @type.cast(DateTime.new(2022, 8, 15, 12)))
  end

  def test_cast_returns_nil_for_unreadable_text
    [ "zzz", "2022-13", "2022-02-31", "08/2022" ].each do |value|
      assert_nil @type.cast(value), value.inspect
    end
  end

  def test_cast_returns_nil_for_a_value_that_is_not_text
    [ [ "2026-09" ], { "a" => "2026-09" }, 202_609 ].each do |value|
      assert_nil @type.cast(value), value.inspect
    end
  end

  # serialize

  def test_serialize_writes_nil_for_a_blank_value
    assert_nil @type.serialize("")
  end

  def test_serialize_returns_a_normalized_date
    assert_equal("2022-08-01", @type.serialize("2022-08"))
  end

  def test_serialize_writes_a_date_as_its_iso_text
    assert_equal("2022-08-15", @type.serialize(Date.new(2022, 8, 15)))
  end

  # What `cast` cannot read would come back nil anyway; the column gets that, not the garbage.
  def test_serialize_writes_nil_for_unreadable_input
    assert_nil @type.serialize("zzz")
  end
end
