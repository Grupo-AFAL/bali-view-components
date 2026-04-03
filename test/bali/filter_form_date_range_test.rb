# frozen_string_literal: true

require "test_helper"

class BaliFilterFormDateRangeTest < ActiveSupport::TestCase
  def setup
    Studio.delete_all
    @s1 = Studio.create!(name: "Studio 1", created_at: "2024-01-01")
    @s2 = Studio.create!(name: "Studio 2", created_at: "2024-01-15")
    @s3 = Studio.create!(name: "Studio 3", created_at: "2024-02-01")
  end

  def test_filters_by_date_range_from_simple_filters
    params = ActionController::Parameters.new(q: { created_at: "2024-01-01 to 2024-01-20" })
    simple_filters = [ { attribute: :created_at, type: :date_range } ]

    ff = Bali::FilterForm.new(Studio.all, params, simple_filters: simple_filters)
    results = ff.result

    assert_includes results, @s1
    assert_includes results, @s2
    assert_not_includes results, @s3
  end

  def test_filters_by_single_date_from_simple_filters
    params = ActionController::Parameters.new(q: { created_at: "2024-01-15" })
    simple_filters = [ { attribute: :created_at, type: :date_range } ]

    ff = Bali::FilterForm.new(Studio.all, params, simple_filters: simple_filters)
    results = ff.result

    assert_not_includes results, @s1
    assert_includes results, @s2
    assert_not_includes results, @s3
  end
end
