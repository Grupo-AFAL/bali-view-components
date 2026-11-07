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

  # A hash built in a view or in an `available_attributes` override. `FilterForm.filter_attribute`
  # raises the same when the class loads (filter_form_operators_test.rb).
  test "an attribute hash with an operator its type does not offer raises" do
    { %i[gt] => "gt", %i[eq gt] => "gt", [] => "(empty list)" }.each do |operators, unknown|
      error = assert_raises(ArgumentError, operators.inspect) do
        Bali::Filters::Operators.for_attribute({ key: :code, type: :text, operators: operators })
      end
      assert_match "attribute :code: type :text offers no operator #{unknown} (valid:", error.message
    end
  end

  test "a default operator outside the attribute's operators raises" do
    error = assert_raises(ArgumentError) do
      Bali::Filters::Operators.default_for({ key: :code, type: :text, operators: %i[eq], default_operator: :gt })
    end
    assert_match "attribute :code: default_operator: :gt is not among its operators (eq)", error.message
  end
end
