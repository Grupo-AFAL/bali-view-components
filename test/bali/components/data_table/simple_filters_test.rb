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
      fields: [ :name ],
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

  def test_renders_preserved_params_as_hidden_fields
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: @filters, preserved_params: { "group_by" => "genre" }
    ))
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_drops_blank_preserved_params
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: @filters, preserved_params: { "group_by" => "" }
    ))
    assert_no_selector("input[type=hidden][name=group_by]", visible: :all)
  end

  # Same semantics as Filters::Component (shared PreservedParams module): the browser drops the
  # action's query on a GET submit, so a host passing a `url:` with params of its own (a scope
  # like `status=historico`) lost them on every submit of the simple row. The Clear link already
  # kept them (clear_href); the submit did not.
  def test_reemits_non_filter_query_params_from_url_as_hidden_fields
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test?status=historico&page=2", filters: @filters
    ))
    assert_selector("form input[type=hidden][name=status][value=historico]", visible: :all)
    assert_selector("form input[type=hidden][name=page][value='2']", visible: :all)
  end

  def test_does_not_reemit_filter_or_clearing_params_from_url
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test?q%5Bstatus_eq%5D=active&clear_filters=true&clear_search=true&saved_view=5&page=2",
      filters: @filters
    ))
    assert_no_selector("input[type=hidden][name='q[status_eq]']", visible: :all)
    assert_no_selector("input[type=hidden][name=clear_filters]", visible: :all)
    assert_no_selector("input[type=hidden][name=clear_search]", visible: :all)
    assert_no_selector("input[type=hidden][name=saved_view]", visible: :all)
    assert_selector("form input[type=hidden][name=page][value='2']", visible: :all)
  end

  # Deduplication rule inherited from Filters: on a key collision the explicit hash wins over the
  # URL's query — without it, a host already passing the param by hand through `preserved_params:`
  # would emit it twice.
  def test_explicit_preserved_params_win_over_url_query_params
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test?group_by=status", filters: @filters, preserved_params: { "group_by" => "genre" }
    ))
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
    assert_no_selector("input[type=hidden][name=group_by][value=status]", visible: :all)
  end

  def test_renders_visible_filter_label
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_selector("label", text: "Status")
    assert_selector("select[name='q[status_eq]']")
  end

  def test_omits_label_caption_when_label_absent
    filters_without_label = [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        value: nil
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: filters_without_label))
    assert_no_selector("label")
    assert_selector("select[name='q[status_eq]']")
  end

  # `clear_filters` is NOT cosmetic: it is the only param that deletes the filter cache on the
  # server (`Rails.cache.delete(cache_key)`). Without it the link navigates to the bare URL, which
  # with persistence on is indistinguishable from "no filter arrived" — and the listing restores
  # what the user has just cleared. The other two clearing routes (AppliedTags#clear_all_url and
  # the JS clearFiltersAndClose) do send it; this one had been left out, and these tests pinned
  # the bare URL as if it were the contract.
  def test_shows_clear_button_when_show_clear_is_true
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, show_clear: true))
    assert_link(href: "/test?clear_filters=true")
  end

  # Clearing drops the FILTERS, not the view state: the link carries the same pairs the submit
  # emits as hidden fields. Without this, the param the submit had just preserved was lost through
  # the control right next to it.
  def test_clear_link_carries_the_preserved_params
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: @filters, show_clear: true, preserved_params: { tab: "archived" }
    ))
    assert_link(href: "/test?clear_filters=true&tab=archived")
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

  # This template called `slim_select_field` with the two positional hashes #785 retired,
  # so every index page carrying a slim_select filter warned on the host's behalf about a
  # call written here (#797). The id and the width class come out of what used to be the
  # second hash: assert them, or "fix" the warning by deleting the hash and still pass.
  def test_slim_select_filter_does_not_leak_the_form_builder_deprecation_to_the_host
    slim_select_filter = [
      {
        attribute: :status,
        type: :slim_select,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        label: "Status",
        value: "active"
      }
    ]

    warning = capture_deprecation do
      render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: slim_select_filter))
    end

    assert_nil(warning)
    assert_selector("select#simple-filter-q-status_eq.w-full")
    assert_selector("option[selected]", text: "Active")
  end

  def test_slim_select_filter_selects_the_current_value
    slim_select_filter = [
      {
        attribute: :status,
        type: :slim_select,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        label: "Status",
        value: "active"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: slim_select_filter))
    assert_selector("option[selected]", text: "Active")
  end

  def test_slim_select_filter_selects_the_default_value_when_no_current_value
    slim_select_filter = [
      {
        attribute: :status,
        type: :slim_select,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: "All",
        label: "Status",
        value: nil,
        default: "inactive"
      }
    ]
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: slim_select_filter))
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

  # #677: the caller declares columns, not the Ransack parameter. This is the same
  # `search:` hash the Filters panel takes.
  def test_search_input_name_is_derived_from_several_columns
    search = @search.merge(fields: %i[name email])
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: search))
    assert_selector("input[type='text'][name='q[name_or_email_cont]']")
    assert_selector("input#simple-filter-search-q-name_or_email_cont")
  end

  def test_an_unknown_search_option_raises
    error = assert_raises(ArgumentError) do
      Bali::DataTable::SimpleFilters::Component.new(
        url: "/test", filters: @filters, search: { field_name: "q[name_cont]" }
      )
    end
    assert_includes(error.message, ":field_name")
  end

  def test_search_input_opts_out_of_password_manager_autofill
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    # A search box is not a login field; we opt out of autofill so 1Password and friends do not offer
    # credentials when it is focused.
    assert_selector("input[type='text'][autocomplete='off'][data-1p-ignore]")
    assert_selector("input[type='text'][data-lpignore='true'][data-form-type='other']")
  end

  def test_search_input_uses_default_width_classes
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("div.w-48.sm\\:w-96.shrink-0")
  end

  def test_search_input_uses_custom_width_when_provided
    search_with_width = @search.merge(width: "w-64 sm:w-full")
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: search_with_width))
    assert_selector("div.w-64.sm\\:w-full.shrink-0")
    assert_no_selector("div.w-48")
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
    assert_link(href: "/test?clear_filters=true")
  end

  # A `url:` with a query string is the normal case when the host passes `request.fullpath` or a path
  # helper with params: the param is ADDED, without overwriting what already travelled or duplicating.
  def test_the_clear_link_keeps_the_params_the_listing_url_already_carried
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
                    url: "/test?scope=mine", filters: @filters, show_clear: true))

    href = page.find("a[href*='clear_filters']")[:href]
    assert_equal("true", Rack::Utils.parse_query(URI(href).query)["clear_filters"])
    assert_equal("mine", Rack::Utils.parse_query(URI(href).query)["scope"])
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

  # Persistence toggle tests

  def test_persist_enabled_returns_false_by_default
    component = Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, storage_id: "records_filters")
    refute(component.persist_enabled?)
  end

  def test_persist_enabled_returns_true_when_explicitly_enabled
    component = Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, storage_id: "records_filters", persist_enabled: true)
    assert(component.persist_enabled?)
  end

  def test_does_not_render_persistence_toggle_when_storage_id_is_absent
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters))
    assert_no_selector('[data-controller="filter-persistence"]')
  end

  def test_renders_persistence_toggle_when_storage_id_is_present
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, storage_id: "records_filters"))
    assert_selector('[data-controller="filter-persistence"]')
    assert_selector('[data-filter-persistence-storage-id-value="records_filters"]')
  end

  def test_persistence_toggle_shows_disabled_icon_by_default
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, storage_id: "records_filters"))
    assert_selector('[data-filter-persistence-target="iconDisabled"]:not(.hidden)')
    assert_selector('[data-filter-persistence-target="iconEnabled"].hidden')
    assert_selector('[data-filter-persistence-enabled-value="false"]')
  end

  def test_persistence_toggle_shows_enabled_icon_when_persist_enabled_is_true
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, storage_id: "records_filters", persist_enabled: true))
    assert_selector('[data-filter-persistence-target="iconEnabled"]:not(.hidden)')
    assert_selector('[data-filter-persistence-target="iconDisabled"].hidden')
    assert_selector('[data-filter-persistence-enabled-value="true"]')
  end

  # The DataTable switches it off because it paints the checkbox as a toolbar control of its own.
  def test_does_not_render_persistence_toggle_when_persistence_toggle_is_false
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: @filters, storage_id: "records_filters", persistence_toggle: false
    ))
    assert_no_selector('[data-controller="filter-persistence"]')
  end

  def test_persistence_toggle_renders_with_search_only_and_no_filters
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [], search: @search, storage_id: "records_filters"))
    assert_selector('[data-controller="filter-persistence"]')
  end

  # --- The button's caption names what the button does ---

  def test_the_button_says_search_when_there_is_nothing_to_filter
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [], search: @search))

    assert_selector("button[type=submit]", text: I18n.t("bali_view.filters.submit_search"))
    assert_no_selector("button[type=submit]", text: I18n.t("bali_view.simple_filters.apply"))
  end

  def test_the_button_says_filter_as_soon_as_there_is_a_filter
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("button[type=submit]", text: I18n.t("bali_view.simple_filters.apply"))
  end

  # --- auto_submit: pills that filter on click (#725) ---
  #
  # The wiring is all `data-`: the form mounts `submit-on-change` and every opted-in filter control
  # sends it the action. The asserts are on those attributes because they are the contract — the
  # behaviour itself is covered by cypress/e2e/simple-filters-auto-submit.

  def auto_submit_pill_filters(auto_submit:)
    [
      {
        attribute: :status,
        collection: [ %w[Draft draft], %w[Published published] ],
        label: "Status",
        type: :radio_group,
        auto_submit: auto_submit
      },
      {
        attribute: :kind,
        collection: [ %w[Public public], %w[Private private] ],
        label: "Kind",
        type: :toggle_group,
        predicate: :in,
        auto_submit: auto_submit
      }
    ]
  end

  def test_auto_submit_mounts_the_controller_and_wires_every_pill
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: auto_submit_pill_filters(auto_submit: true)
    ))

    assert_selector('form[data-controller="submit-on-change"]')
    assert_selector('input[type="radio"][data-action="change->submit-on-change#submit"]', count: 2)
    assert_selector('input[type="checkbox"][data-action="change->submit-on-change#submit"]', count: 2)
  end

  # The default is off, and that is what leaves any row that already existed untouched.
  def test_without_auto_submit_the_row_carries_no_wiring_at_all
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: auto_submit_pill_filters(auto_submit: false)
    ))

    assert_no_selector('form[data-controller="submit-on-change"]')
    assert_no_selector("[data-action*='submit-on-change']")
    assert_selector('form[data-turbo-frame="_top"]')
  end

  def test_auto_submit_wires_only_the_filters_that_asked_for_it
    filters = auto_submit_pill_filters(auto_submit: false)
    filters[0][:auto_submit] = true

    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: filters))

    assert_selector('form[data-controller="submit-on-change"]')
    assert_selector('input[type="radio"][data-action="change->submit-on-change#submit"]', count: 2)
    assert_no_selector('input[type="checkbox"][data-action]')
  end

  # #996: a native select is a finished choice too — its change fires when the menu closes on a
  # selection — so it auto-submits just like the pills.
  def test_auto_submit_wires_a_native_select
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [
      { attribute: :genre, label: "Genre", type: :select, auto_submit: true,
        collection: [ %w[Action action], %w[Comedy comedy] ], blank: "All" }
    ]))

    assert_selector('form[data-controller="submit-on-change"]')
    assert_selector('select[data-action="change->submit-on-change#submit"]', count: 1)
  end

  # A range is submitted between one half of the value and the other, so the component ignores it
  # even when the instance hash (which skips the DSL's validation) asks for it.
  def test_auto_submit_is_ignored_outside_the_single_choice_widgets
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [
      { attribute: :founded_year, label: "Founded", type: :number_range, auto_submit: true }
    ]))

    assert_no_selector('form[data-controller="submit-on-change"]')
    assert_no_selector("[data-action*='submit-on-change']")
  end

  # --- Period presets on a date_range (#725) ---

  def preset_filter(**overrides)
    [ { attribute: :created_at, type: :date_range, label: "Created",
        presets: %w[today this_week this_month] }.merge(overrides) ]
  end

  def render_presets(**overrides)
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: preset_filter(**overrides)
    ))
  end

  def test_a_date_range_with_presets_renders_a_period_select
    render_presets

    assert_selector("select[data-time-period-field-target=select] option[value=today]",
                    text: I18n.t("bali_view.simple_filters.presets.today"), visible: :all)
    assert_selector("select[data-time-period-field-target=select] option[value=this_month]",
                    text: I18n.t("bali_view.simple_filters.presets.this_month"), visible: :all)
  end

  # 725-D6: the widget REUSES `f.time_period_group`'s controller, not one of its own.
  def test_the_widget_wires_the_shared_time_period_field_controller
    render_presets

    assert_selector('[data-controller="time-period-field"]', visible: :all)
    assert_selector('[data-time-period-field-custom-value="custom"]', visible: :all)
    # The `-value` suffix is spelled out deliberately: without it Stimulus reads nothing, the
    # controller is left with no container to show and "Personalizado…" never reveals the picker —
    # a silence only visible in the browser.
    assert_selector('[data-time-period-field-date-input-container-class-value="flatpickr"]',
                    visible: :all)
  end

  # A single control with a `name`: two would send the param twice and the last would win, which is
  # not necessarily the one the user sees.
  def test_only_the_hidden_field_carries_the_param_name
    render_presets

    assert_selector("input[type=hidden][name='q[created_at]'][data-time-period-field-target=input]",
                    count: 1, visible: :all)
    assert_no_selector("select[name='q[created_at]']", visible: :all)
    assert_no_selector("input[type=text][name='q[created_at]']", visible: :all)
  end

  def test_a_date_range_without_presets_keeps_the_bare_picker
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: [ { attribute: :created_at, type: :date_range, label: "Created" } ]
    ))

    assert_no_selector('[data-controller="time-period-field"]', visible: :all)
    assert_selector("input[name='q[created_at]']", visible: :all)
  end

  def test_the_chosen_token_comes_back_selected_and_the_picker_stays_hidden
    render_presets(value: "this_month")

    assert_selector("option[value=this_month][selected]", visible: :all)
    assert_selector("input[type=hidden][name='q[created_at]'][value=this_month]", visible: :all)
    assert_selector(".flatpickr.hidden", visible: :all)
  end

  # A value that is not a token is a range the user picked: the select lands on "Personalizado…"
  # and the picker comes back showing it.
  def test_an_explicit_range_lands_on_custom_with_the_picker_showing
    render_presets(value: "2026-08-01 to 2026-08-06")

    assert_selector("option[value=custom][selected]", visible: :all)
    assert_selector(".flatpickr:not(.hidden)", visible: :all)
    assert_selector("input[value='2026-08-01 to 2026-08-06']", visible: :all)
  end

  def test_the_blank_option_says_any_date_unless_the_filter_names_it
    render_presets
    assert_selector("option[value='']", text: I18n.t("bali_view.simple_filters.presets.any"),
                    visible: :all)

    render_presets(blank: "Whenever")
    assert_selector("option[value='']", text: "Whenever", visible: :all)
  end

  # The caption points at the SELECT, which is the control the user operates — the picker is that
  # same control's fourth state, not a second filter.
  def test_the_caption_names_the_period_select
    render_presets

    assert_selector("label[for='simple-filter-q-created_at']", text: "Created")
    assert_selector("select#simple-filter-q-created_at", visible: :all)
  end
end

# #1155. A filter control with no accessible name is a WCAG 4.1.2 failure: the reader reaches a
# bare "combo box" and the user does not know what they are filtering. The caption was the only
# thing naming most of the branches, so `label: false` —which exists since #882 for a row that
# already explains itself— left every one of them mute.
#
# These tests look at the MARKUP. Two branches cannot be verified this way, because the control the
# user operates is built by JS and is not in the HTML the ERB renders (SlimSelect's
# `div[role=combobox]` and flatpickr's altInput): for those two, what is pinned here is the
# attribute the JS copies, and the accessibility tree is measured in the browser.
# The way hosts actually declare this (identity, afal-apps, bali-auth): the class DSL and a `blank:`
# that is a proc, for a translation that cannot be frozen at class-load time. The crossing of a
# proc `blank:` + `label: false` + `filter_attribute` was not covered end to end.
class ProcBlankUncaptionedFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, simple: true, advanced: false,
                   options: [ %w[Action action] ],
                   blank: -> { "Todos los géneros" },
                   label: false
end

class BaliSimpleFiltersAccessibleNameTest < ComponentTestCase
  # Guarded on purpose. The deduplication Set lives on the component, so anyone reverting the fix
  # to watch these tests go red is left without the accessor — and unguarded, all 21 tests died
  # with the same `NoMethodError` in `setup`, which masks exactly what is being asserted.
  def setup
    component = Bali::DataTable::SimpleFilters::Component
    return unless component.respond_to?(:unnamed_filter_warnings_issued=)

    component.unnamed_filter_warnings_issued = Set.new
  end

  def test_a_select_without_caption_is_named_by_its_blank_option
    render_filter(attribute: :year, collection: [ %w[2026 2026] ], blank: "Todos los años",
                  label: false)

    assert_no_selector("label")
    assert_selector("select[aria-label='Todos los años']")
  end

  def test_an_explicit_aria_label_wins_over_the_blank_option
    render_filter(attribute: :year, collection: [ %w[2026 2026] ], blank: "Todos los años",
                  label: false, aria_label: "Año fiscal")

    assert_selector("select[aria-label='Año fiscal']")
  end

  # A hand-built filter may not carry the `:label` key at all: there is no caption there either.
  def test_a_select_with_no_label_key_at_all_is_named_too
    render_filter(attribute: :year, collection: [ %w[2026 2026] ], blank: "Todos los años")

    assert_selector("select[aria-label='Todos los años']")
  end

  def test_a_captioned_select_keeps_its_markup_untouched
    render_filter(attribute: :status, collection: [ %w[Active active] ], blank: "All",
                  label: "Status")

    assert_selector("label[for='simple-filter-q-status_eq']", text: "Status")
    assert_no_selector("select[aria-label]")
  end

  # `include_blank: true` is valid in Rails and paints an empty option: naming the control "true"
  # would be the same bug as the word "false" further down.
  def test_a_non_string_blank_never_becomes_the_name
    render_filter(attribute: :year, collection: [ %w[2026 2026] ], blank: true, label: false)

    assert_no_selector("select[aria-label]")
  end

  # SlimSelect shrinks the real `<select>` to 1x1 and draws its own `div[role=combobox]`, which
  # takes its name ONLY from the select's aria attributes: the `<label for>` does not travel. So
  # this branch is mute in the captioned case too, which is every host's case today.
  def test_a_captioned_slim_select_points_at_its_caption
    render_filter(attribute: :owner_id, collection: [ %w[Ana ana] ], blank: "All owners",
                  label: "Owner", type: :slim_select)

    assert_selector("select[aria-labelledby='simple-filter-q-owner_id_eq-label']", visible: :all)
    assert_selector("label#simple-filter-q-owner_id_eq-label", text: "Owner")
  end

  def test_an_uncaptioned_slim_select_carries_the_name_itself
    render_filter(attribute: :owner_id, collection: [ %w[Ana ana] ], blank: "All owners",
                  label: false, type: :slim_select)

    assert_selector("select[aria-label='All owners']", visible: :all)
  end

  # The datepicker copies the `label[for]` onto the altInput, and failing that the `aria-label`
  # (datepicker-controller.js#forwardAccessibleName). With no caption there was neither.
  def test_an_uncaptioned_date_filter_carries_an_aria_label
    render_filter(attribute: :signed_on, type: :date, label: false, aria_label: "Fecha de firma")

    assert_selector("input[aria-label='Fecha de firma']", visible: :all)
  end

  # By id and not by `input[type=date]`: the datepicker renders `type="text"` —flatpickr needs the
  # text input for its altInput— so that selector matched nothing and the assertion proved
  # nothing.
  def test_a_captioned_date_filter_keeps_its_markup_untouched
    render_filter(attribute: :signed_on, type: :date, label: "Firmado")

    assert_selector("label[for='simple-filter-q-signed_on_eq']", text: "Firmado")
    assert_selector("input#simple-filter-q-signed_on_eq", visible: :all)
    assert_no_selector("input#simple-filter-q-signed_on_eq[aria-label]", visible: :all)
  end

  # The placeholder came out as the string "false", through the `|| filter[:label]`.
  def test_an_uncaptioned_date_filter_never_gets_a_false_placeholder
    render_filter(attribute: :signed_on, type: :date, label: false, aria_label: "Fecha")

    assert_no_selector("input[placeholder=false]", visible: :all)
  end

  # The presets select always has something to fall back on: `blank:`, and failing that "Any date".
  def test_the_presets_select_is_named_even_with_no_caption_and_no_blank
    render_presets_filter(label: false)

    assert_selector(
      "select#simple-filter-q-created_at[aria-label='#{I18n.t('bali_view.simple_filters.presets.any')}']",
      visible: :all
    )
  end

  # The "Personalizado…" picker is a second control of the same group and NEVER has a
  # `<label for>`: its `aria-label` was always emitted, and with `label: false` it said "false".
  def test_the_presets_picker_is_never_named_false
    render_presets_filter(label: false)

    assert_no_selector("[aria-label=false]", visible: :all)
    assert_selector("input#simple-filter-q-created_at-custom[aria-label]", visible: :all)
  end

  # The picker is named by the filter's caption, not by `aria_label:`: the YARD promises that where
  # there is a caption the caption wins, and WCAG 2.5.3 asks that the accessible name contain the
  # visible label. The other five branches satisfied that on their own —with a caption they emit no
  # `aria-label`—; this one produced two names for the same group.
  def test_the_presets_picker_is_named_by_the_caption_not_by_aria_label
    render_presets_filter(label: "Creado", aria_label: "OTRO NOMBRE")

    assert_selector("label[for='simple-filter-q-created_at']", text: "Creado")
    assert_selector("input#simple-filter-q-created_at-custom[aria-label='Creado']", visible: :all)
    assert_no_selector("[aria-label='OTRO NOMBRE']", visible: :all)
  end

  # The presets SELECT falls back to its blank option ("Cualquier fecha"). The picker cannot
  # inherit that: the user opens it precisely to say the opposite, so that name is the reverse of
  # what the control does. It is named after what it is.
  def test_the_presets_picker_is_never_named_after_the_blank_option
    render_presets_filter(label: false, blank: "Cualquier fecha")

    assert_selector("select#simple-filter-q-created_at[aria-label='Cualquier fecha']",
                    visible: :all)
    assert_selector(
      "input#simple-filter-q-created_at-custom" \
      "[aria-label='#{I18n.t('bali_view.simple_filters.presets.custom_range')}']",
      visible: :all
    )
  end

  def test_an_uncaptioned_presets_filter_names_both_controls_from_aria_label
    render_presets_filter(label: false, aria_label: "Creado entre")

    assert_selector("select#simple-filter-q-created_at[aria-label='Creado entre']", visible: :all)
    assert_selector("input#simple-filter-q-created_at-custom[aria-label='Creado entre']",
                    visible: :all)
  end

  # The other side, branch by branch: with a caption, `aria_label:` names nothing in any of the
  # nine. Nobody asserted this combination before, and it is where the code and its YARD
  # contradicted each other.
  def test_a_caption_wins_over_aria_label_in_every_branch
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: every_widget_captioned
    ))

    every_widget_captioned.each { |filter| assert_text(filter[:label]) }
    refute_match(/OTRO NOMBRE/, rendered_content,
                 "con caption, `aria_label:` se ignora en todas las ramas")
  end

  # The boolean paints its own caption next to the switch: with `label: false` it printed the word
  # "false" on screen and the switch was called that.
  def test_a_boolean_filter_never_prints_the_word_false
    render_filter(attribute: :featured, type: :boolean, label: false, aria_label: "Sólo destacados")

    refute_match(/>false</, rendered_content)
    assert_selector("input[type=checkbox][aria-label='Sólo destacados']", visible: :all)
  end

  def test_a_captioned_boolean_still_prints_its_caption
    render_filter(attribute: :featured, type: :boolean, label: "Destacados")

    assert_text("Destacados")
    assert_no_selector("input[type=checkbox][aria-label]", visible: :all)
  end

  # The pill groups and the number range already name each control; what they lacked without a
  # caption was the name of the GROUP.
  def test_an_uncaptioned_pill_group_is_still_a_named_group
    render_filter(attribute: :kind, collection: [ %w[Public public] ], type: :toggle_group,
                  label: false, aria_label: "Tipo")

    assert_selector("[role=group][aria-label='Tipo']", visible: :all)
  end

  def test_an_uncaptioned_number_range_is_still_a_named_group
    render_filter(attribute: :amount, type: :number_range, label: false, aria_label: "Importe")

    assert_selector("[role=group][aria-label='Importe']", visible: :all)
  end

  # The sweep that prevents a #1155-bis: no branch renders an operable control without a name.
  # `hidden` and `submit` are out because they cannot be reached.
  #
  # The quick search travels in the sweep with its `label:` set: it is the row's other control and
  # its placeholder does NOT name it —a placeholder disappears as you type— so if the search's
  # `aria-label` stopped being emitted this test would flag it just like a mute filter.
  def test_no_simple_filter_control_ships_without_an_accessible_name
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/test", filters: every_widget,
      search: { fields: [ :name ], placeholder: "Search by name...", label: "Search movies" }
    ))

    nameless = page.all("select, input", visible: :all).reject do |control|
      next true if %w[hidden submit].include?(control[:type])
      # The two halves of a number range are called "Min" and "Max" through their placeholder —the
      # last resort of accname— and the group wrapping them carries the filter's name.
      next true if control[:type] == "number" && control[:placeholder].present?

      control[:"aria-label"].present? || control[:"aria-labelledby"].present? ||
        (control[:id].present? && page.has_selector?("label[for='#{control[:id]}']", visible: :all))
    end

    assert_empty(nameless.map { |c| c[:name] || c[:id] },
                 "todo control de la fila tiene que salir con nombre accesible")
  end

  # The whole chain, the way it arrives from a host: FilterForm → `simple_filters_config` → the
  # component. It is what leaves afal-apps' three selects named without the host touching a line.
  def test_a_filter_form_declaring_label_false_reaches_the_component_named
    form = Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new({}),
      simple_filters: [ { attribute: :genre, collection: [ %w[Action action] ],
                          blank: "Todos los géneros", label: false } ]
    )
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/movies", filters: form.simple_filters_config
    ))

    assert_no_selector("label")
    assert_selector("select[aria-label='Todos los géneros']")
  end

  # And through the class DSL with a `blank:` proc, which is how real hosts declare it:
  # `simple_filters_config` resolves the proc before the filter reaches the component.
  def test_a_proc_blank_declared_by_the_class_dsl_reaches_the_component_as_the_name
    form = ProcBlankUncaptionedFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::SimpleFilters::Component.new(
      url: "/movies", filters: form.simple_filters_config
    ))

    assert_no_selector("label")
    assert_selector("select[aria-label='Todos los géneros']")
  end

  # With no `aria_label:`, no caption and no `blank:` to fall back on there is no name left.
  # Blowing up at render would break production over an accessibility defect, so it warns where it
  # can be fixed and carries on.
  def test_warns_when_a_filter_has_no_name_left_to_fall_back_on
    log = capture_bali_log do
      in_development { render_filter(attribute: :featured, type: :boolean, label: false) }
    end

    assert_match(/featured/, log)
    assert_match(/aria_label/, log)
  end

  # The warning's text said "the control ships without a name" for the three multi-control branches
  # too, where it is false: each pill is named by its option and the two halves of a range come out
  # "Min" and "Max" through their placeholder. What is anonymous there is the GROUP, which without
  # a name is not even emitted.
  def test_the_warning_for_a_multi_control_filter_names_the_group_not_the_control
    log = capture_bali_log do
      in_development { render_filter(attribute: :amount, type: :number_range, label: false) }
    end

    assert_match(/GROUP/, log)
    refute_match(/the control renders with no accessible name/, log)
    assert_no_selector("[role=group]", visible: :all)
  end

  def test_the_warning_for_a_single_control_filter_still_names_the_control
    log = capture_bali_log do
      in_development { render_filter(attribute: :featured, type: :boolean, label: false) }
    end

    assert_match(/the control renders with no accessible name/, log)
    refute_match(/GROUP/, log)
  end

  # Once per control per process: without the deduplication a host's suite repeats the same line on
  # every page that paints the row. `setup` resets the Set, so this can only be asserted inside a
  # single test.
  def test_the_warning_sounds_once_per_control_and_process
    log = capture_bali_log do
      in_development do
        3.times { render_filter(attribute: :featured, type: :boolean, label: false) }
      end
    end

    assert_equal(1, log.scan(/SimpleFilters "featured"/).size, log)
  end

  # `presets:` always resolves a name —`preset_blank_label` falls back to a translated string— so
  # `filter_has_a_name?`'s exemption has to keep it quiet.
  def test_a_presets_filter_never_warns_even_with_no_caption_and_no_aria_label
    log = capture_bali_log { in_development { render_presets_filter(label: false) } }

    assert_empty(log)
  end

  def test_stays_silent_when_the_filter_resolves_a_name
    log = capture_bali_log do
      in_development do
        render_filter(attribute: :year, collection: [ %w[2026 2026] ], blank: "Todos los años",
                      label: false)
      end
    end

    assert_empty(log)
  end

  # It does not sound in production: a host does not learn about an accessibility defect from their
  # users' log, and there the line is pure noise.
  def test_stays_silent_in_production
    log = capture_bali_log do
      in_env("production") { render_filter(attribute: :featured, type: :boolean, label: false) }
    end

    assert_empty(log)
  end

  private

  def render_filter(**filter)
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [ filter ]))
  end

  def render_presets_filter(**overrides)
    render_filter(**{ attribute: :created_at, type: :date_range, presets: %i[today] }
      .merge(overrides))
  end

  # The same nine branches, all with a caption AND with an `aria_label:` that must not beat it.
  def every_widget_captioned
    every_widget.each_with_index.map do |filter, index|
      filter.merge(label: "Caption #{index}", aria_label: "OTRO NOMBRE")
    end
  end

  def every_widget
    [
      { attribute: :year, collection: [ %w[2026 2026] ], blank: "Todos los años", label: false },
      { attribute: :owner_id, collection: [ %w[Ana ana] ], blank: "All owners", label: false,
        type: :slim_select },
      { attribute: :signed_on, type: :date, label: false, aria_label: "Fecha de firma" },
      { attribute: :created_at, type: :date_range, label: false, aria_label: "Creado entre" },
      { attribute: :period, type: :date_range, presets: %i[today], label: false },
      { attribute: :featured, type: :boolean, label: false, aria_label: "Destacados" },
      { attribute: :kind, collection: [ %w[Public public] ], type: :toggle_group, label: false,
        aria_label: "Tipo" },
      { attribute: :status, collection: [ %w[Draft draft] ], type: :radio_group, label: false,
        aria_label: "Estado" },
      { attribute: :amount, type: :number_range, label: false, aria_label: "Importe" }
    ]
  end

  def in_development(&)
    in_env("development", &)
  end

  def in_env(name)
    previous = Rails.env
    Rails.env = name
    yield
  ensure
    Rails.env = previous
  end

  def capture_bali_log
    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    yield
    io.string.scan(/\[Bali\].*/).join("\n")
  ensure
    Rails.logger = previous
  end
end
