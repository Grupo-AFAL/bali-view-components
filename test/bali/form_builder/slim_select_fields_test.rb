# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderSlimSelectFieldsTest < FormBuilderTestCase
  # #slim_select_group

  def test_slim_select_group_renders_a_label_and_input_within_a_wrapper
    result = builder.slim_select_group(:status, Movie.statuses.to_a)
    assert_html(result, "fieldset.fieldset")
  end

  def test_slim_select_group_renders_a_label
    result = builder.slim_select_group(:status, Movie.statuses.to_a)
    assert_html(result, "label.fieldset-legend", text: "Status")
  end

  def test_slim_select_group_renders_a_div_with_a_slim_select_controller
    result = builder.slim_select_group(:status, Movie.statuses.to_a)
    assert_html(result, 'div[data-controller="slim-select"]')
  end

  def test_slim_select_group_renders_a_select
    result = builder.slim_select_group(:status, Movie.statuses.to_a)
    assert_html(result, 'select#movie_status[name="movie[status]"][data-slim-select-target="select"]')
    Movie.statuses.each do |name, value|
      assert_html(result, "option[value=\"#{value}\"]", text: name)
    end
  end

  # input_name / input_id options (issue #547)

  def test_slim_select_group_honors_input_name_option
    result = builder.slim_select_group(:status, Movie.statuses.to_a, input_name: "thing[status]")
    assert_html(result, 'select[name="thing[status]"]')
  end

  def test_slim_select_group_honors_input_id_option
    result = builder.slim_select_group(:status, Movie.statuses.to_a, input_id: "thing_status")
    assert_html(result, "select#thing_status")
  end

  # #slim_select_field

  def test_slim_select_field_renders_a_div_with_control_class
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, "div.control")
  end

  def test_slim_select_field_renders_a_div_with_a_slim_select_controller
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, 'div[data-controller="slim-select"]')
  end

  def test_slim_select_field_renders_a_select
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, 'select#movie_status[name="movie[status]"][data-slim-select-target="select"]')
    Movie.statuses.each do |name, value|
      assert_html(result, "option[value=\"#{value}\"]", text: name)
    end
  end

  # include_blank / prompt -> SlimSelect placeholder (issue gobierno-corporativo#570)

  def test_slim_select_field_include_blank_renders_a_slim_select_placeholder_option
    result = builder.slim_select_field(:status, Movie.statuses.to_a, include_blank: "Choose a status")
    assert_html(result, 'option[data-placeholder="true"][value=""]', text: "Choose a status")
  end

  def test_slim_select_field_prompt_renders_a_slim_select_placeholder_option
    result = builder.slim_select_field(:status, Movie.statuses.to_a, prompt: "Pick one")
    assert_html(result, 'option[data-placeholder="true"][value=""]', text: "Pick one")
  end

  def test_slim_select_field_without_blank_renders_no_placeholder_option
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, "option[data-placeholder]", count: 0)
  end

  def test_slim_select_field_include_blank_keeps_the_real_options_selectable
    result = builder.slim_select_field(:status, Movie.statuses.to_a, include_blank: "Choose a status")
    Movie.statuses.each do |name, value|
      assert_html(result, "option[value=\"#{value}\"]:not([data-placeholder])", text: name)
    end
  end

  # include_blank + grouped (optgroup) choices — the placeholder promotion must not
  # break Rails' grouped-choices detection, which looks only at the FIRST element
  # (afal-apps report_schedules regression, 27/07/2026)

  GROUPED_CHOICES = [
    [ "Fiction", [ [ "Dune", "fiction:1" ], [ "Neuromancer", "fiction:2" ] ] ],
    [ "Non-fiction", [ [ "Cosmos", "nonfiction:1" ] ] ]
  ].freeze

  def test_slim_select_field_include_blank_with_grouped_choices_keeps_optgroups
    result = builder.slim_select_field(:status, GROUPED_CHOICES, include_blank: "All")
    assert_html(result, 'optgroup[label="Fiction"] option[value="fiction:1"]', text: "Dune")
    assert_html(result, 'optgroup[label="Non-fiction"] option[value="nonfiction:1"]', text: "Cosmos")
  end

  def test_slim_select_field_include_blank_with_grouped_choices_keeps_the_blank_option
    result = builder.slim_select_field(:status, GROUPED_CHOICES, include_blank: "All")
    assert_html(result, 'option[value=""]', text: "All")
  end

  def test_slim_select_field_include_blank_with_grouped_choices_honors_selected
    result = builder.slim_select_field(:status, GROUPED_CHOICES,
                                       include_blank: "All", selected: "fiction:2")
    assert_html(result, 'option[value="fiction:2"][selected]')
  end

  def test_slim_select_field_applies_daisyui_select_classes
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, "select.select.select-bordered")
  end

  def test_slim_select_field_applies_the_slim_select_wrapper_class
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, "div.slim-select")
  end

  # select_all option

  def test_slim_select_field_select_all_option_renders_select_all_button
    result = builder.slim_select_field(:status, Movie.statuses.to_a, select_all: true)
    assert_html(result, 'a.ss-toggle-btn[data-action="slim-select#selectAll"]')
  end

  def test_slim_select_field_select_all_option_renders_deselect_all_button_with_hidden_class
    result = builder.slim_select_field(:status, Movie.statuses.to_a, select_all: true)
    assert_html(result, 'a.ss-toggle-btn.hidden[data-action="slim-select#deselectAll"]')
  end

  def test_slim_select_field_select_all_option_sets_data_targets_on_buttons
    result = builder.slim_select_field(:status, Movie.statuses.to_a, select_all: true)
    assert_html(result, 'a[data-slim-select-target="selectAllButton"]')
    assert_html(result, 'a[data-slim-select-target="deselectAllButton"]')
  end

  def test_slim_select_field_select_all_option_uses_i18n_for_button_text
    I18n.with_locale(:en) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a, select_all: true)
      select_all_text = I18n.t("bali_view.form_builder.slim_select.select_all")
      deselect_all_text = I18n.t("bali_view.form_builder.slim_select.deselect_all")
      assert_html(result, "a", text: select_all_text)
      assert_html(result, "a", text: deselect_all_text)
    end
  end

  # custom classes

  def test_slim_select_field_custom_classes_appends_custom_class_to_select
    result = builder.slim_select_field(:status, Movie.statuses.to_a, html: { class: "custom-class" })
    assert_html(result, "select.select.select-bordered.custom-class")
  end

  def test_slim_select_field_custom_classes_applies_select_class_to_wrapper
    result = builder.slim_select_field(:status, Movie.statuses.to_a, html: { select_class: "wrapper-class" })
    assert_html(result, "div.slim-select.wrapper-class")
  end

  # validation errors

  def test_slim_select_field_with_validation_errors_renders_select_with_error_class
    resource.errors.add(:status, :invalid)
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, "select.select.select-bordered.select-error")
  end

  def test_slim_select_field_with_validation_errors_displays_error_message
    resource.errors.add(:status, :invalid)
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, "p.text-error")
  end

  # custom data attributes

  def test_slim_select_field_custom_data_attributes_merges_custom_data_attributes_with_slim_select_target
    result = builder.slim_select_field(:status, Movie.statuses.to_a, html:                                        { data: { turbo_frame: "_top", custom: "value" } })
    assert_html(result, 'select[data-slim-select-target="select"]')
    assert_html(result, 'select[data-turbo-frame="_top"]')
    assert_html(result, 'select[data-custom="value"]')
  end

  def test_slim_select_field_custom_data_attributes_preserves_slim_select_target_when_no_custom_data_provided
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, 'select[data-slim-select-target="select"]')
  end

  # multiple select

  def test_slim_select_field_multiple_select_renders_a_multiple_select
    result = builder.slim_select_field(:status, Movie.statuses.to_a, html: { multiple: true })
    assert_html(result, 'select[multiple="multiple"]')
  end

  # stimulus data values

  def test_slim_select_field_stimulus_data_values_sets_close_on_select_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, close_on_select: false)
    assert_html(result, 'div[data-slim-select-close-on-select-value="false"]')
  end

  def test_slim_select_field_stimulus_data_values_sets_allow_deselect_option_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, allow_deselect_option: true)
    assert_html(result, 'div[data-slim-select-allow-deselect-option-value="true"]')
  end

  def test_slim_select_field_stimulus_data_values_sets_placeholder_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, html: { placeholder: "Choose one" })
    assert_html(result, 'div[data-slim-select-placeholder-value="Choose one"]')
  end

  # The other six SlimSelect texts already go through `bali_view.form_builder.slim_select.*`;
  # the placeholder was the odd one out — no data-attribute emitted, so the Stimulus
  # controller's English default ('Select value') won on every call site that did not pass
  # `html: { placeholder: }`.
  def test_slim_select_field_placeholder_value_defaults_to_the_translated_placeholder
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, 'div[data-slim-select-placeholder-value="Select value"]')
  end

  def test_slim_select_field_placeholder_value_default_is_translated
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a)
      assert_html(result, 'div[data-slim-select-placeholder-value="Selecciona una opción"]')
    end
  end

  def test_slim_select_field_html_placeholder_wins_over_the_translated_default
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a, html: { placeholder: "Choose one" })
      assert_html(result, 'div[data-slim-select-placeholder-value="Choose one"]')
    end
  end

  def test_slim_select_field_stimulus_data_values_sets_add_items_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, add_items: true)
    assert_html(result, 'div[data-slim-select-add-items-value="true"]')
  end

  def test_slim_select_field_stimulus_data_values_sets_show_search_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, show_search: false)
    assert_html(result, 'div[data-slim-select-show-search-value="false"]')
  end

  def test_slim_select_field_stimulus_data_values_sets_custom_search_placeholder
    result = builder.slim_select_field(:status, Movie.statuses.to_a, search_placeholder: "Find...")
    assert_html(result, 'div[data-slim-select-search-placeholder-value="Find..."]')
  end

  def test_slim_select_field_stimulus_data_values_sets_add_to_body_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, add_to_body: true)
    assert_html(result, 'div[data-slim-select-add-to-body-value="true"]')
  end

  def test_slim_select_field_stimulus_data_values_sets_content_width_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a, content_width: ">240px")
    assert_html(result, 'div[data-slim-select-content-width-value=">240px"]')
  end

  def test_slim_select_field_omits_content_width_value_when_not_provided
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    refute_match(/data-slim-select-content-width-value/, result)
  end

  # ajax options

  def test_slim_select_field_ajax_options_sets_ajax_url_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_url: "/api/search",
                                       ajax_param_name: "query",
                                       ajax_value_name: "id",
                                       ajax_text_name: "name",
                                       ajax_placeholder: "Loading...")
    assert_html(result, 'div[data-slim-select-ajax-url-value="/api/search"]')
  end

  def test_slim_select_field_ajax_options_sets_ajax_param_name_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_url: "/api/search",
                                       ajax_param_name: "query")
    assert_html(result, 'div[data-slim-select-ajax-param-name-value="query"]')
  end

  def test_slim_select_field_ajax_options_sets_ajax_value_name_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_value_name: "id")
    assert_html(result, 'div[data-slim-select-ajax-value-name-value="id"]')
  end

  def test_slim_select_field_ajax_options_sets_ajax_text_name_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_text_name: "name")
    assert_html(result, 'div[data-slim-select-ajax-text-name-value="name"]')
  end

  def test_slim_select_field_ajax_options_sets_ajax_placeholder_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_placeholder: "Loading...")
    assert_html(result, 'div[data-slim-select-ajax-placeholder-value="Loading..."]')
  end

  # after_change_fetch options

  def test_slim_select_field_after_change_fetch_options_sets_after_change_fetch_url_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       after_change_fetch_url: "/api/update",
                                       after_change_fetch_method: "PATCH")
    assert_html(result, 'div[data-slim-select-after-change-fetch-url-value="/api/update"]')
  end

  def test_slim_select_field_after_change_fetch_options_sets_after_change_fetch_method_value
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       after_change_fetch_url: "/api/update",
                                       after_change_fetch_method: "PATCH")
    assert_html(result, 'div[data-slim-select-after-change-fetch-method-value="PATCH"]')
  end

  # constants

  def test_slim_select_field_constants_defines_wrapper_class
    assert_equal "slim-select", Bali::FormBuilder::SlimSelectFields::WRAPPER_CLASS
  end

  def test_slim_select_field_constants_defines_select_class
    assert_equal "select select-bordered", Bali::FormBuilder::SlimSelectFields::SELECT_CLASS
  end

  def test_slim_select_field_constants_defines_toggle_button_class
    assert_equal "ss-toggle-btn", Bali::FormBuilder::SlimSelectFields::TOGGLE_BUTTON_CLASS
  end

  def test_slim_select_field_constants_defines_default_options_as_frozen
    assert Bali::FormBuilder::SlimSelectFields::DEFAULT_OPTIONS.frozen?
  end
end
