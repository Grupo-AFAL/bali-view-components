# frozen_string_literal: true

require "test_helper"

class BaliFiltersAppliedTagsComponentTest < ComponentTestCase
  def setup
    @available_attributes = [
      { key: :name, label: "Name", type: :text },
      { key: :status, label: "Status", type: :select,
        options: [ %w[Active active], %w[Inactive inactive] ] },
      { key: :verified, label: "Verified", type: :boolean }
    ]
    @filter_groups = [
      {
        combinator: "or",
        conditions: [
          { attribute: "name", operator: "cont", value: "John" },
          { attribute: "status", operator: "eq", value: "active" }
        ]
      }
    ]
  end


  def test_with_no_active_filters_renders_nothing_when_filter_groups_is_empty
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: [], available_attributes: @available_attributes, url: "/users"
    ))
    assert_no_selector(".applied-filters")
  end


  def test_with_no_active_filters_renders_nothing_when_conditions_have_no_values
    filter_groups = [
      {
        combinator: "or", conditions: [ { attribute: "name", operator: "cont", value: "" } ]
      }
    ]
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_no_selector(".applied-filters")
  end


  def test_with_active_filters_renders_the_applied_filters_container
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_selector(".applied-filters")
    assert_selector('[data-controller="applied-tags"]')
  end


  def test_with_active_filters_renders_filter_tags_as_badges
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_selector(".badge", count: 2)
  end


  def test_with_active_filters_displays_attribute_label_in_tag
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_text("Name")
    assert_text("Status")
  end


  def test_with_active_filters_displays_operator_label_in_tag
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_text("contains")
    assert_text("is")
  end


  def test_with_active_filters_displays_value_in_tag
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_text("John")
    assert_text("Active") # Displays label, not value
  end


  def test_with_active_filters_renders_remove_button_for_each_tag
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_selector('button[data-action="applied-tags#removeFilter"]', count: 2)
  end


  def test_with_active_filters_renders_clear_all_link_when_multiple_filters
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: @filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_link("Clear all")
  end


  def test_with_active_filters_does_not_render_clear_all_link_with_single_filter
    single_filter = [
      {
        combinator: "or", conditions: [ { attribute: "name", operator: "cont", value: "John" } ]
      }
    ]
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: single_filter, available_attributes: @available_attributes, url: "/users"
    ))
    assert_no_link("Clear all")
  end


  def test_value_labels_shows_option_label_for_select_type
    filter_groups = [
      {
        combinator: "or", conditions: [ { attribute: "status", operator: "eq", value: "active" } ]
      }
    ]
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_text("Active")
  end


  def test_value_labels_shows_yes_no_for_boolean_type
    filter_groups = [
      {
        combinator: "or", conditions: [ { attribute: "verified", operator: "eq", value: "true" } ]
      }
    ]
    render_inline(Bali::Filters::AppliedTags::Component.new(
      filter_groups: filter_groups, available_attributes: @available_attributes, url: "/users"
    ))
    assert_text("Yes")
  end


  def test_any_filters_returns_true_when_filters_have_values
    filter_groups = [
      {
        combinator: "or", conditions: [ { attribute: "name", operator: "cont", value: "John" } ]
      }
    ]
    component = Bali::Filters::AppliedTags::Component.new(
      filter_groups: filter_groups, available_attributes: @available_attributes, url: "/users"
    )
    assert(component.any_filters?)
  end


  def test_any_filters_returns_false_when_no_filters_have_values
    filter_groups = [
      {
        combinator: "or", conditions: [ { attribute: "name", operator: "cont", value: "" } ]
      }
    ]
    component = Bali::Filters::AppliedTags::Component.new(
      filter_groups: filter_groups, available_attributes: @available_attributes, url: "/users"
    )
    refute(component.any_filters?)
  end
end
