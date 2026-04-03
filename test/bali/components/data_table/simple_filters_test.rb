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

  def test_renders_filters_without_labels
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_no_selector(".label-text")
    assert_selector("select[name='q[status_eq]']")
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

  def test_search_parameter_renders_search_input_with_placeholder
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("input[placeholder='Search by name...']")
    assert_no_selector(".label-text")
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

  def test_renders_toggle_group_filters
    toggle_filters = [
      {
        attribute: :category,
        collection: [ %w[Electronics electronics], %w[Books books], %w[Clothing clothing] ],
        label: "Categories",
        type: :toggle_group,
        predicate: :in,
        value: %w[electronics books]
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: toggle_filters))

    assert_selector(".join")
    assert_selector("input[type='checkbox'][name='q[category_in][]'][value='electronics'][checked].join-item", visible: false)
    assert_selector("input[type='checkbox'][name='q[category_in][]'][value='books'][checked].join-item", visible: false)
    assert_selector("input[type='checkbox'][name='q[category_in][]'][value='clothing'].join-item", visible: false)
    assert_no_selector("input[type='checkbox'][checked][value='clothing']", visible: false)

    # Check for active state (checked attribute)
    assert_selector("input[value='electronics'][checked]", visible: false)
    assert_selector("input[value='books'][checked]", visible: false)
    assert_no_selector("input[value='clothing'][checked]", visible: false)

    # DaisyUI uses aria-label for button text in the filter group
    assert_selector("input[aria-label='Electronics']")
    assert_selector("input[aria-label='Books']")
    assert_selector("input[aria-label='Clothing']")
  end

  def test_renders_date_range_filters
    date_filters = [
      {
        attribute: :created_at,
        label: "Created between",
        type: :date_range
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: date_filters))

    assert_selector(".flatpickr[data-datepicker-mode-value='range']")
    assert_selector("input[name='q[created_at]']")
  end

  def test_persists_date_range_value
    date_filters = [
      {
        attribute: :created_at,
        label: "Created between",
        type: :date_range,
        value: "2024-01-01 to 2024-01-20"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: date_filters))

    assert_selector(".flatpickr[data-datepicker-default-dates-value*='2024-01-01']")
    assert_selector(".flatpickr[data-datepicker-default-dates-value*='2024-01-20']")
    assert_selector("input[value='2024-01-01 to 2024-01-20']")
  end

  # Boolean toggle tests

  def test_renders_boolean_toggle_filter
    boolean_filters = [
      {
        attribute: :featured,
        label: "Featured",
        type: :boolean,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: boolean_filters))

    assert_selector("input[type='checkbox'][name='q[featured_eq]'][value='true'].toggle")
    assert_selector("span", text: "Featured")
  end

  def test_boolean_toggle_checked_when_value_is_true
    boolean_filters = [
      {
        attribute: :featured,
        label: "Featured",
        type: :boolean,
        value: "true"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: boolean_filters))

    assert_selector("input[type='checkbox'][checked].toggle", visible: false)
  end

  def test_boolean_toggle_unchecked_when_value_is_nil
    boolean_filters = [
      {
        attribute: :published,
        label: "Published",
        type: :boolean,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: boolean_filters))

    assert_no_selector("input[type='checkbox'][checked].toggle", visible: false)
  end

  def test_boolean_toggle_sends_hidden_field_for_unchecked
    boolean_filters = [
      {
        attribute: :featured,
        label: "Featured",
        type: :boolean,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: boolean_filters))

    assert_selector("input[type='hidden'][name='q[featured_eq]'][value='']", visible: false)
  end

  # Radio group tests

  def test_renders_radio_group_filter
    radio_filters = [
      {
        attribute: :status,
        collection: [ %w[Draft draft], %w[Published published], %w[Archived archived] ],
        label: "Status",
        type: :radio_group,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: radio_filters))

    assert_selector(".join")
    assert_selector("input[type='radio'][name='q[status_eq]'][value='draft']")
    assert_selector("input[type='radio'][name='q[status_eq]'][value='published']")
    assert_selector("input[type='radio'][name='q[status_eq]'][value='archived']")
    assert_selector("input[aria-label='Draft']")
    assert_selector("input[aria-label='Published']")
    assert_selector("input[aria-label='Archived']")
  end

  def test_radio_group_selects_current_value
    radio_filters = [
      {
        attribute: :status,
        collection: [ %w[Draft draft], %w[Published published] ],
        label: "Status",
        type: :radio_group,
        value: "published"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: radio_filters))

    assert_selector("input[type='radio'][value='published'][checked]", visible: false)
    assert_no_selector("input[type='radio'][value='draft'][checked]", visible: false)
  end

  def test_radio_group_is_single_select
    radio_filters = [
      {
        attribute: :status,
        collection: [ %w[Draft draft], %w[Published published] ],
        label: "Status",
        type: :radio_group,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: radio_filters))

    # All radio inputs share the same name (single-select behavior)
    assert_selector("input[type='radio'][name='q[status_eq]']", count: 2)
  end

  # Number range tests

  def test_renders_number_range_filter
    range_filters = [
      {
        attribute: :amount,
        label: "Amount",
        type: :number_range,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: range_filters))

    assert_selector("input[type='number'][name='q[amount_gteq]']")
    assert_selector("input[type='number'][name='q[amount_lteq]']")
  end

  def test_number_range_preserves_values
    range_filters = [
      {
        attribute: :price,
        label: "Price",
        type: :number_range,
        value: { min: 100, max: 500 }
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: range_filters))

    assert_selector("input[type='number'][name='q[price_gteq]'][value='100']")
    assert_selector("input[type='number'][name='q[price_lteq]'][value='500']")
  end

  def test_number_range_with_custom_placeholders
    range_filters = [
      {
        attribute: :amount,
        label: "Amount",
        type: :number_range,
        placeholder_min: "From",
        placeholder_max: "To",
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: range_filters))

    assert_selector("input[placeholder='From']")
    assert_selector("input[placeholder='To']")
  end

  def test_number_range_with_icon
    range_filters = [
      {
        attribute: :amount,
        label: "Amount",
        type: :number_range,
        icon: "dollar-sign",
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: range_filters))

    assert_selector(".join")
    assert_selector("input[type='number'][name='q[amount_gteq]']")
    assert_selector("input[type='number'][name='q[amount_lteq]']")
  end

  def test_number_range_with_step
    range_filters = [
      {
        attribute: :quantity,
        label: "Quantity",
        type: :number_range,
        step: 1,
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: range_filters))

    assert_selector("input[type='number'][step='1']", count: 2)
  end
end
