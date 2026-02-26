# frozen_string_literal: true

require "test_helper"

class ModelWithNumericAttributesWithCommas
  include Bali::Concerns::NumericAttributesWithCommas

  currency_attribute :price
  percentage_attribute :waste_percentage
end

class BaliConcernsNumericAttributesWithCommasTest < ActiveSupport::TestCase
  def setup
    @model = ModelWithNumericAttributesWithCommas.new
  end


  def test_price_returns_assigned_integer
    @model.price = 10
    assert_equal(10, @model.price)
  end


  def test_price_setter_with_integer
    @model.price = 10
    assert_equal(10, @model.price)
  end


  def test_price_setter_with_decimal
    @model.price = 10.0
    assert_equal(10.0, @model.price)
  end


  def test_price_setter_with_integer_string
    @model.price = "10"
    assert_equal(10, @model.price)
  end


  def test_price_setter_with_decimal_string
    @model.price = "10.0"
    assert_equal(10.0, @model.price)
  end


  def test_price_setter_with_comma_delimited_string
    @model.price = "1,000.50"
    assert_equal(1000.5, @model.price)
  end
end
