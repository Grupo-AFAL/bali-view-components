# frozen_string_literal: true

require "test_helper"

# The text operators depend on the installed ransack: filter_form_text_predicates_test.rb holds
# both lists.
class BaliFiltersOperatorsTest < ActiveSupport::TestCase
  test "each type offers its operators in the order the select shows them" do
    {
      number: %w[eq not_eq gt lt gteq lteq],
      date: %w[eq between gt lt gteq lteq],
      datetime: %w[eq between gt lt gteq lteq],
      select: %w[eq not_eq in not_in],
      boolean: %w[eq]
    }.each do |type, operators|
      assert_equal operators, Bali::Filters::Operators.for_type(type).pluck(:value), type
    end
  end
end
