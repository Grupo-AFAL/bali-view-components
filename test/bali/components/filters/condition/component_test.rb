# frozen_string_literal: true

require "test_helper"

class BaliFiltersConditionComponentTest < ComponentTestCase
  def setup
    @available_attributes = [
      { key: :name, label: "Name", type: :text },
      { key: :status, label: "Status", type: :select,
        options: [ %w[Active active], %w[Inactive inactive] ] },
      { key: :age, label: "Age", type: :number },
      { key: :created_at, label: "Created", type: :date },
      { key: :verified, label: "Verified", type: :boolean }
    ]
    @empty_condition = { attribute: "", operator: "cont", value: "" }
  end

  def test_rendering_renders_the_condition_container
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector(".condition")
    assert_selector('[data-controller="condition"]')
  end

  def test_rendering_renders_attribute_selector_with_all_options
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_select(with_options: %w[Name Status Age Created Verified])
  end

  def test_rendering_renders_operator_selector
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('select[data-condition-target="operator"]')
  end

  def test_rendering_renders_value_input
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('[data-condition-target="valueContainer"]')
  end

  def test_rendering_renders_remove_button
    render_inline(Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('button[data-action="condition#remove"]')
  end

  def test_with_pre_selected_attribute_selects_the_attribute_in_the_dropdown
    condition = { attribute: "name", operator: "cont", value: "John" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('option[value="name"][selected]')
  end

  def test_with_pre_selected_attribute_shows_text_input_for_text_type
    condition = { attribute: "name", operator: "cont", value: "John" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[type="text"][data-condition-target="value"]')
  end

  def test_with_pre_selected_attribute_shows_number_input_for_number_type
    condition = { attribute: "age", operator: "eq", value: "25" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[type="number"][data-condition-target="value"]')
  end

  def test_with_pre_selected_attribute_shows_select_for_select_type
    condition = { attribute: "status", operator: "eq", value: "active" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('select[data-condition-target="value"]')
    assert_select(with_options: %w[Active Inactive])
  end

  def test_with_pre_selected_attribute_shows_select_for_boolean_type
    condition = { attribute: "verified", operator: "eq", value: "true" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('select[data-condition-target="value"]')
    assert_select(with_options: %w[Any Yes No])
  end

  def test_with_pre_selected_attribute_shows_date_input_for_date_type
    condition = { attribute: "created_at", operator: "eq", value: "2026-01-01" }
    render_inline(Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[data-controller="datepicker"]')
  end

  def test_field_name_builds_correct_ransack_field_name
    condition = { attribute: "status", operator: "eq", value: "active" }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 1, condition_index: 0, available_attributes: @available_attributes
    )
    assert_equal("q[g][1][status_eq]", component.field_name)
  end

  def test_field_name_uses_placeholder_for_empty_attribute
    component = Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    assert_equal("q[g][0][__ATTR___cont]", component.field_name)
  end

  def test_operators_for_current_type_returns_operators_for_the_selected_attribute_type
    condition = { attribute: "age", operator: "eq", value: "" }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    operators = component.operators_for_current_type
    assert_includes(operators.pluck(:value), "eq")
    assert_includes(operators.pluck(:value), "gt")
    assert_includes(operators.pluck(:value), "lt")
  end

  def test_operators_for_current_type_defaults_to_text_operators_when_no_attribute_selected
    component = Bali::Filters::Condition::Component.new(
      condition: @empty_condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    operators = component.operators_for_current_type
    assert_includes(operators.pluck(:value), "cont")
    assert_includes(operators.pluck(:value), "eq")
  end

  def test_multiple_operator_returns_true_for_in_operator
    condition = { attribute: "status", operator: "in", value: [] }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    assert(component.multiple_operator?)
  end

  def test_multiple_operator_returns_true_for_not_in_operator
    condition = { attribute: "status", operator: "not_in", value: [] }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    assert(component.multiple_operator?)
  end

  def test_multiple_operator_returns_false_for_eq_operator
    condition = { attribute: "status", operator: "eq", value: "active" }
    component = Bali::Filters::Condition::Component.new(
      condition: condition, group_index: 0, condition_index: 0, available_attributes: @available_attributes
    )
    refute(component.multiple_operator?)
  end
end
