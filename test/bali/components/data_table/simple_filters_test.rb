# frozen_string_literal: true

require "test_helper"

class BaliDataTableSimpleFiltersComponentTest < ComponentTestCase
  def setup
    @filters = [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        label: "Status",
        value: nil
      }
    ]
    @search = {
      field_name: "q[name_cont]",
      value: nil,
      placeholder: "Search by name..."
    }
  end


  def test_renders_filter_selects
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_selector("select[name='q[status_eq]']")
    assert_selector("option", text: "All")
    assert_selector("option", text: "Active")
    assert_selector("option", text: "Inactive")
  end


  def test_renders_submit_button
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_selector('button[type="submit"]')
  end


  def test_renders_labels
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_selector(".label-text", text: "Status")
  end


  def test_shows_clear_button_when_show_clear_is_true
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, show_clear: true))
    assert_link(href: "/test")
  end


  def test_hides_clear_button_when_show_clear_is_false
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, show_clear: false))
    assert_no_link(text: /Clear/i)
  end


  def test_does_not_render_when_filters_are_empty
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: []))
    assert_no_selector("form")
  end


  def test_selects_the_current_value
    filters_with_value = [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        label: "Status",
        value: "active"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: filters_with_value))
    assert_selector("option[selected]", text: "Active")
  end


  def test_selects_the_default_value_when_no_current_value
    filters_with_default = [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        label: "Status",
        value: nil,
        default: "inactive"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: filters_with_default))
    assert_selector("option[selected]", text: "Inactive")
  end


  def test_renders_multiple_filters
    multi_filters = [
      {
        attribute: :status,
        collection: [ %w[Active active] ],
        blank: "All Statuses",
        label: "Status",
        value: nil
      },
      {
        attribute: :category,
        collection: [ %w[Electronics electronics] ],
        blank: "All Categories",
        label: "Category",
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: multi_filters))
    assert_selector("select[name='q[status_eq]']")
    assert_selector("select[name='q[category_eq]']")
    assert_selector(".label-text", text: "Status")
    assert_selector(".label-text", text: "Category")
  end


  def test_uses_turbo_frame_top_for_form_submission
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_selector('form[data-turbo-frame="_top"]')
  end


  def test_search_parameter_renders_search_input_when_search_is_provided
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("input[type='text'][name='q[name_cont]']")
    assert_selector("input[placeholder='Search by name...']")
  end


  def test_search_parameter_does_not_render_search_input_when_search_is_nil
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_no_selector("input[type='text']")
  end


  def test_search_parameter_renders_search_input_before_filter_selects
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("input[type='text'][name='q[name_cont]']")
    assert_selector("select[name='q[status_eq]']")
  end


  def test_search_parameter_preserves_search_value_after_submission
    search_with_value = @search.merge(value: "SAP")
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: search_with_value))
    assert_selector("input[value='SAP']")
  end


  def test_search_parameter_renders_search_label
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector(".label-text", text: "Search")
  end


  def test_search_parameter_renders_custom_search_label
    search_with_label = @search.merge(label: "Find records")
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: search_with_label))
    assert_selector(".label-text", text: "Find records")
  end


  def test_search_parameter_shows_clear_button_when_show_clear_is_true_with_search
    search_with_value = @search.merge(value: "test")
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: search_with_value, show_clear: true))
    assert_link(href: "/test")
  end


  def test_search_parameter_does_not_show_clear_button_when_show_clear_is_false_even_with_search_value
    search_with_value = @search.merge(value: "test")
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: search_with_value))
    assert_no_link(text: /Clear/i)
  end


  def test_search_parameter_renders_with_search_only_and_no_filters
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [], search: @search))
    assert_selector("form")
    assert_selector("input[type='text'][name='q[name_cont]']")
    assert_no_selector("select")
  end


  def test_search_parameter_submits_search_and_filters_together_in_one_form
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("form")
    assert_selector("input[name='q[name_cont]']")
    assert_selector("select[name='q[status_eq]']")
  end
end
