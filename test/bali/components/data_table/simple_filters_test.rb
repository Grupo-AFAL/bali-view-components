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

  # Misma semántica que Filters::Component (módulo compartido PreservedParams): el browser
  # descarta el query de la action en un submit GET, así que un host que pasa `url:` con
  # params propios (un scope como `status=historico`) los perdía en cada submit del form
  # simple. El link Limpiar ya los conservaba (clear_href); el submit no.
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

  # Regla de deduplicación heredada de Filters: en colisión de key, el hash explícito gana
  # sobre el query de la URL — sin esto un host que ya pasaba el param a mano por
  # `preserved_params:` lo emitiría dos veces.
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

  # `clear_filters` NO es cosmético: es el único param que en el server borra la caché de
  # filtros (`Rails.cache.delete(cache_key)`). Sin él, el link navega a la URL pelada, que
  # con la persistencia encendida es indistinguible de "no vino ningún filtro" — y el
  # listado restaura lo que el usuario acaba de limpiar. Las otras dos rutas de limpieza
  # (AppliedTags#clear_all_url y clearFiltersAndClose del JS) sí lo mandan; ésta se había
  # quedado afuera, y estos tests fijaban la URL pelada como si fuera el contrato.
  def test_shows_clear_button_when_show_clear_is_true
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, show_clear: true))
    assert_link(href: "/test?clear_filters=true")
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
    # Un buscador no es un campo de login; salimos del autofill para que 1Password
    # y otros no ofrezcan credenciales al enfocarlo.
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

  # Una `url:` con query string es el caso normal cuando el host pasa `request.fullpath` o un
  # path helper con params: el param se AGREGA, sin pisar lo que ya viajaba ni duplicarse.
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

  # El DataTable lo apaga porque pinta el marcador como control propio de la toolbar.
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

  # --- El rótulo del botón nombra lo que el botón hace ---

  def test_the_button_says_search_when_there_is_nothing_to_filter
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: [], search: @search))

    assert_selector("button[type=submit]", text: I18n.t("bali_view.filters.submit_search"))
    assert_no_selector("button[type=submit]", text: I18n.t("bali_view.simple_filters.apply"))
  end

  def test_the_button_says_filter_as_soon_as_there_is_a_filter
    render_inline(Bali::DataTable::SimpleFilters::Component.new(url: "/test", filters: @filters, search: @search))
    assert_selector("button[type=submit]", text: I18n.t("bali_view.simple_filters.apply"))
  end
  # --- Presets de periodo en un date_range (#725) ---

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

  # 725-D6: el widget REUSA el controller de `f.time_period_group`, no uno propio.
  def test_the_widget_wires_the_shared_time_period_field_controller
    render_presets

    assert_selector('[data-controller="time-period-field"]', visible: :all)
    assert_selector('[data-time-period-field-custom-value="custom"]', visible: :all)
    # El sufijo `-value` va deletreado a propósito: sin él Stimulus no lee nada, el
    # controller se queda sin contenedor que mostrar y "Personalizado…" no revela el
    # picker — un silencio que sólo se ve en el browser.
    assert_selector('[data-time-period-field-date-input-container-class-value="flatpickr"]',
                    visible: :all)
  end

  # Un solo control con `name`: dos mandarían el param dos veces y ganaría el último, que no
  # es necesariamente el que el usuario ve.
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

  # Un valor que no es token es un rango que el usuario eligió: el select cae en
  # "Personalizado…" y el picker vuelve mostrándolo.
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

  # El caption apunta al SELECT, que es el control que el usuario opera — el picker es el
  # cuarto estado de ese mismo control, no un segundo filtro.
  def test_the_caption_names_the_period_select
    render_presets

    assert_selector("label[for='simple-filter-q-created_at']", text: "Created")
    assert_selector("select#simple-filter-q-created_at", visible: :all)
  end
end
