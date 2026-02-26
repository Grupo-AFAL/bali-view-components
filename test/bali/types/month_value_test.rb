# frozen_string_literal: true

require "test_helper"

class BaliTypesMonthValueTest < ActiveSupport::TestCase
  def setup
    @subject = Bali::Types::MonthValue.new
  end

  # integration

  def test_integration_with_a_model_casts_a_month_value_from_month_string_to_a_date_value
    character = Character.new(birth_month: "2022-08")
    assert_equal(Date.parse("2022-08-01"), character.birth_month)
  end

  # cast

  def test_cast_return_a_nil_if_value_is_blank
    assert_nil(@subject.cast(""))
  end


  def test_cast_returns_a_date_object
    assert_equal(Date.parse("2022-08-01"), @subject.cast("2022-08"))
  end

  # serialize

  def test_serialize_returns_value_if_is_blank
    assert_equal("", @subject.serialize(""))
  end


  def test_serialize_returns_a_normalized_date
    assert_equal("2022-08-01", @subject.serialize("2022-08"))
  end
end
