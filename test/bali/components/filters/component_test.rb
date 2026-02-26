# frozen_string_literal: true

require "test_helper"

class BaliFiltersComponentTest < ComponentTestCase
  def setup
    @available_attributes = [
      { key: :name, label: "Name", type: :text },
      { key: :status, label: "Status", type: :select,
        options: [ %w[Active active], %w[Inactive inactive] ] },
      { key: :age, label: "Age", type: :number },
      { key: :created_at, label: "Created", type: :date },
      { key: :verified, label: "Verified", type: :boolean }
    ]
  end

  def test_rendering_renders_the_component
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    ))
    assert_selector(".filters")
    assert_selector('[data-controller="filters"]')
  end

  def test_rendering_renders_a_filter_group_by_default
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    ))
    assert_selector(".filter-group")
    assert_selector('[data-controller="filter-group"]')
  end

  def test_rendering_renders_available_attributes_in_the_dropdown
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    ))
    assert_select(with_options: %w[Name Status Age Created Verified])
  end

  def test_rendering_renders_apply_and_reset_buttons
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    ))
    assert_button("Apply")
    assert_button("Reset")
  end

  def test_rendering_renders_add_group_button
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    ))
    assert_selector('[data-filters-target="addGroupButton"]')
  end

  def test_with_initial_filter_groups_renders_pre_populated_conditions
    filter_groups = [
      {
        combinator: "or", conditions: [
          { attribute: "status", operator: "eq", value: "active" }
        ]
      }
    ]
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, filter_groups: filter_groups
    ))
    assert_selector(".filter-group")
    assert_selector('option[value="status"]', text: "Status")
  end

  def test_with_initial_filter_groups_renders_multiple_groups_with_combinator
    filter_groups = [
      { combinator: "or", conditions: [ { attribute: "status", operator: "eq", value: "active" } ] },
      { combinator: "and", conditions: [ { attribute: "name", operator: "cont", value: "test" } ] }
    ]
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, filter_groups: filter_groups, combinator: :and
    ))
    assert_selector(".filter-group", count: 2)
    assert_selector('input[type="hidden"][name="q[m]"]', visible: :hidden)
    assert_button("AND")
    assert_button("OR")
  end

  def test_operators_provides_correct_operators_for_text_type
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: [ { key: :name, type: :text } ]
    )
    operators = component.operators_for_type(:text)
    assert_includes(operators.pluck(:value), "cont")
    assert_includes(operators.pluck(:value), "eq")
    assert_includes(operators.pluck(:value), "start")
    assert_includes(operators.pluck(:value), "end")
  end

  def test_operators_provides_correct_operators_for_number_type
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: [ { key: :age, type: :number } ]
    )
    operators = component.operators_for_type(:number)
    assert_includes(operators.pluck(:value), "eq")
    assert_includes(operators.pluck(:value), "gt")
    assert_includes(operators.pluck(:value), "lt")
    assert_includes(operators.pluck(:value), "gteq")
    assert_includes(operators.pluck(:value), "lteq")
  end

  def test_operators_provides_correct_operators_for_date_type
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: [ { key: :created_at, type: :date } ]
    )
    operators = component.operators_for_type(:date)
    assert_includes(operators.pluck(:value), "eq")
    assert_includes(operators.pluck(:value), "gt")
    assert_includes(operators.pluck(:value), "lt")
    assert_includes(operators.pluck(:value), "gteq")
    assert_includes(operators.pluck(:value), "lteq")
  end

  def test_operators_provides_correct_operators_for_select_type
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: [ { key: :status, type: :select } ]
    )
    operators = component.operators_for_type(:select)
    assert_includes(operators.pluck(:value), "eq")
    assert_includes(operators.pluck(:value), "not_eq")
  end

  def test_operators_provides_correct_operators_for_boolean_type
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: [ { key: :verified, type: :boolean } ]
    )
    operators = component.operators_for_type(:boolean)
    assert_equal([ "eq" ], operators.pluck(:value))
  end

  def test_persistence_toggle_returns_false_for_persistence_available_when_no_storage_id
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    )
    refute(component.persistence_available?)
  end

  def test_persistence_toggle_returns_true_for_persistence_available_when_storage_id_is_present
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters"
    )
    assert(component.persistence_available?)
  end

  def test_persistence_toggle_returns_false_for_persist_enabled_by_default
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters"
    )
    refute(component.persist_enabled?)
  end

  def test_persistence_toggle_returns_true_for_persist_enabled_when_explicitly_enabled
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters", persist_enabled: true
    )
    assert(component.persist_enabled?)
  end

  def test_persistence_toggle_does_not_render_persistence_toggle_when_storage_id_is_absent
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    ))
    assert_no_selector('[data-controller="filter-persistence"]')
  end

  def test_persistence_toggle_renders_persistence_toggle_when_storage_id_is_present
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters"
    ))
    assert_selector('[data-controller="filter-persistence"]')
  end

  def test_persistence_toggle_shows_disabled_icon_by_default
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters"
    ))
    assert_selector('[data-filter-persistence-target="iconDisabled"]:not(.hidden)')
    assert_selector('[data-filter-persistence-target="iconEnabled"].hidden')
  end

  def test_persistence_toggle_shows_enabled_icon_when_persist_enabled_is_true
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters", persist_enabled: true
    ))
    assert_selector('[data-filter-persistence-target="iconEnabled"]:not(.hidden)')
    assert_selector('[data-filter-persistence-target="iconDisabled"].hidden')
  end

  def test_persistence_toggle_renders_auto_saved_text_in_footer_only_when_persistence_is_enabled
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters", persist_enabled: true
    ))
    assert_text("Auto-saved")
  end

  def test_persistence_toggle_does_not_render_auto_saved_text_when_persistence_is_disabled
    render_inline(Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes, storage_id: "users_filters", persist_enabled: false
    ))
    assert_no_text("Auto-saved")
  end

  def test_preserved_query_params_extracts_non_filter_params_from_url
    component = Bali::Filters::Component.new(
      url: "/users?page=2&per=25&q[name_cont]=test", available_attributes: @available_attributes
    )
    assert_equal([ %w[page 2], %w[per 25] ].sort, component.preserved_query_params.sort)
  end

  def test_preserved_query_params_handles_nested_params
    component = Bali::Filters::Component.new(
      url: "/users?sort[column]=name&sort[direction]=asc", available_attributes: @available_attributes
    )
    assert_equal([ [ "sort[column]", "name" ], [ "sort[direction]", "asc" ] ].sort, component.preserved_query_params.sort)
  end

  def test_preserved_query_params_handles_array_params
    component = Bali::Filters::Component.new(
      url: "/users?ids[]=1&ids[]=2&ids[]=3", available_attributes: @available_attributes
    )
    assert_equal([ [ "ids[]", "1" ], [ "ids[]", "2" ], [ "ids[]", "3" ] ].sort, component.preserved_query_params.sort)
  end

  def test_preserved_query_params_returns_empty_array_when_url_has_no_query_params
    component = Bali::Filters::Component.new(
      url: "/users", available_attributes: @available_attributes
    )
    assert_equal([], component.preserved_query_params)
  end

  def test_preserved_query_params_excludes_q_params
    component = Bali::Filters::Component.new(
      url: "/users?page=2&q[name_cont]=test&q[status_eq]=active", available_attributes: @available_attributes
    )
    assert_equal([ %w[page 2] ], component.preserved_query_params)
  end

  def test_preserved_query_params_excludes_clear_filters_and_clear_search_params
    component = Bali::Filters::Component.new(
      url: "/users?page=2&clear_filters=true&clear_search=true", available_attributes: @available_attributes
    )
    assert_equal([ %w[page 2] ], component.preserved_query_params)
  end

  def test_preserved_params_hidden_fields_renders_hidden_fields_for_preserved_params
    render_inline(Bali::Filters::Component.new(
      url: "/users?page=2&per=25", available_attributes: @available_attributes
    ))
    assert_selector('input[type="hidden"][name="page"][value="2"]', visible: :hidden)
    assert_selector('input[type="hidden"][name="per"][value="25"]', visible: :hidden)
  end

  def test_preserved_params_hidden_fields_does_not_render_hidden_fields_for_filter_params
    render_inline(Bali::Filters::Component.new(
      url: "/users?page=2&q[name_cont]=test", available_attributes: @available_attributes
    ))
    assert_selector('input[type="hidden"][name="page"][value="2"]', visible: :hidden)
    assert_no_selector('input[type="hidden"][name="q[name_cont]"]', visible: :hidden)
  end
end
