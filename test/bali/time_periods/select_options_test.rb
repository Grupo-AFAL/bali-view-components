# frozen_string_literal: true

require "test_helper"

class BaliTimePeriodsSelectOptionsTest < ActiveSupport::TestCase
  def test_yearly_quarter_returns_5_options_yearly_4_quarters
    options = Bali::TimePeriods::SelectOptions.yearly_quarter
    assert_equal(5, options.length)
  end

  def test_yearly_quarter_includes_yearly_option_with_i18n
    options = Bali::TimePeriods::SelectOptions.yearly_quarter
    assert_equal(I18n.t("bali.time_periods.yearly"), options.first.first)
  end

  def test_yearly_quarter_includes_q1_q4_options
    options = Bali::TimePeriods::SelectOptions.yearly_quarter
    labels = options.map(&:first)
    assert_includes(labels, "Q1")
    assert_includes(labels, "Q2")
    assert_includes(labels, "Q3")
    assert_includes(labels, "Q4")
  end

  def test_yearly_quarter_returns_date_ranges_as_values
    options = Bali::TimePeriods::SelectOptions.yearly_quarter
    options.each do |_label, range|
      assert_kind_of(Range, range)
    end
  end

  def test_months_returns_12_options
    options = Bali::TimePeriods::SelectOptions.months
    assert_equal(12, options.length)
  end

  def test_months_uses_localized_month_names
    options = Bali::TimePeriods::SelectOptions.months
    month_names = I18n.t("date.month_names").compact
    option_labels = options.map(&:first)
    assert_equal(month_names, option_labels)
  end

  def test_trailing_returns_5_options
    options = Bali::TimePeriods::SelectOptions.trailing
    assert_equal(5, options.length)
  end

  def test_trailing_includes_common_periods
    options = Bali::TimePeriods::SelectOptions.trailing
    labels = options.map(&:first)
    assert_includes(labels, I18n.t("bali.time_periods.yesterday"))
    assert_includes(labels, I18n.t("bali.time_periods.last_7_days"))
    assert_includes(labels, I18n.t("bali.time_periods.last_30_days"))
  end
end
