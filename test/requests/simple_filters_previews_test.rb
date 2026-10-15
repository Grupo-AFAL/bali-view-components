# frozen_string_literal: true

require "test_helper"

# The `date_range_presets` preview offered a range spelled with " to ", which `?locale=es`
# splits on " a ": the picker got one date out of it (#1495).
class SimpleFiltersPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEW = "/lookbook/preview/bali/data_table/simple_filters/date_range_presets"

  def test_the_explicit_range_choice_reaches_the_picker_as_two_dates_in_every_locale
    %w[en es].each do |locale|
      get PREVIEW, params: { locale: locale, created_at: "explicit_range" }
      assert_response :ok

      picker = css_select("[data-datepicker-mode-value=range]").sole
      assert_equal %w[2026-01-01 2026-03-31], JSON.parse(picker["data-datepicker-default-dates-value"]),
                   "in #{locale}"
    end
  end
end
