# frozen_string_literal: true

require "test_helper"

# The component tests render the class, not the previews; requesting one over HTTP is the only
# path where a broken preview shows.
class FiltersPreviewsTest < ActionDispatch::IntegrationTest
  def test_the_applied_restricted_operators_draw_each_end_of_a_between_with_its_own_operator
    %w[true false].each do |popover|
      get "/lookbook/preview/bali/filters/restricted_operators_applied", params: { popover: popover }

      assert_response :ok
      %w[gteq lteq].each do |operator|
        assert_select "select[data-condition-target='operator']:not([disabled]) option[value='#{operator}'][selected]", 1
      end
    end
  end
end
