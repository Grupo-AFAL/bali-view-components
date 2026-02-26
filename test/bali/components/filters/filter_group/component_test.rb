# frozen_string_literal: true

require "test_helper"

class BaliFiltersFilterGroupComponentTest < ComponentTestCase
  def setup
    @available_attributes = [
      { key: :name, label: "Name", type: :text },
      { key: :status, label: "Status", type: :select,
        options: [ %w[Active active], %w[Inactive inactive] ] }
    ]
    @default_group = {
      combinator: "or",
      conditions: [ { attribute: "", operator: "cont", value: "" } ]
    }
    @group_with_conditions = {
      combinator: "and",
      conditions: [
        { attribute: "name", operator: "cont", value: "John" },
        { attribute: "status", operator: "eq", value: "active" }
      ]
    }
  end


  def test_rendering_renders_the_filter_group_container
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @default_group, index: 0, available_attributes: @available_attributes
    ))
    assert_selector(".filter-group")
    assert_selector('[data-controller="filter-group"]')
  end


  def test_rendering_renders_the_combinator_hidden_input
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @default_group, index: 0, available_attributes: @available_attributes
    ))
    assert_selector('input[type="hidden"][name="q[g][0][m]"]', visible: :hidden)
  end


  def test_rendering_renders_conditions
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @default_group, index: 0, available_attributes: @available_attributes
    ))
    assert_selector(".condition")
    assert_selector('[data-controller="condition"]')
  end


  def test_rendering_renders_add_condition_button
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @default_group, index: 0, available_attributes: @available_attributes
    ))
    assert_button("Add condition")
  end


  def test_with_multiple_conditions_renders_all_conditions
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @group_with_conditions, index: 0, available_attributes: @available_attributes
    ))
    assert_selector(".condition", count: 2)
  end


  def test_with_multiple_conditions_renders_combinator_toggle_for_subsequent_conditions
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @group_with_conditions, index: 0, available_attributes: @available_attributes
    ))
    assert_text("Where")
    assert_button("AND")
    assert_button("OR")
  end


  def test_with_multiple_conditions_highlights_the_active_combinator
    render_inline(Bali::Filters::FilterGroup::Component.new(
      group: @group_with_conditions, index: 0, available_attributes: @available_attributes
    ))
    assert_selector("button.btn-primary", text: "AND")
    assert_selector("button.btn-outline", text: "OR")
  end


  def test_combinator_defaults_to_or
    component = Bali::Filters::FilterGroup::Component.new(
      group: { conditions: [ { attribute: "", operator: "cont", value: "" } ] },
      index: 0,
      available_attributes: @available_attributes
    )
    assert_equal("or", component.combinator)
  end


  def test_combinator_uses_the_group_combinator_value
    component = Bali::Filters::FilterGroup::Component.new(
      group: { combinator: "and", conditions: [] },
      index: 0,
      available_attributes: @available_attributes
    )
    assert_equal("and", component.combinator)
  end


  def test_group_field_prefix_builds_the_correct_ransack_field_prefix
    component = Bali::Filters::FilterGroup::Component.new(
      group: @default_group, index: 2, available_attributes: @available_attributes
    )
    assert_equal("q[g][2]", component.group_field_prefix)
  end
end
