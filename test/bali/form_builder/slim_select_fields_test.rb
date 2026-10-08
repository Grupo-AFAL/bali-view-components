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

  # Accessible name (#1253). The Ruby half: the attribute SlimSelect copies onto its
  # combobox, and the error pair (aria-invalid, aria-describedby) that
  # slim-select-controller.js#forwardAccessibility carries across (#1270).
  # cypress/e2e/slim-select-accessible-name.cy.js reads the name, description and invalid
  # state that result.

  def test_slim_select_group_points_the_select_at_its_caption
    result = builder.slim_select_group(:status, Movie.statuses.to_a)

    assert_html(result, "label#movie_status_label[for=movie_status]", text: "Status")
    assert_html(result, "select#movie_status[aria-labelledby=movie_status_label]")
  end

  def test_slim_select_group_points_at_its_caption_when_input_id_moves_the_select
    result = builder.slim_select_group(:status, Movie.statuses.to_a, input_id: "thing_status")

    assert_html(result, "label#movie_status_label[for=thing_status]")
    assert_html(result, "select#thing_status[aria-labelledby=movie_status_label]")
  end

  def test_slim_select_group_keeps_the_error_pair_beside_the_caption
    resource.errors.add(:status, :invalid)
    result = builder.slim_select_group(:status, Movie.statuses.to_a)

    assert_html(result, "select[aria-labelledby=movie_status_label][aria-invalid=true]" \
                        "[aria-describedby=movie_status_error]")
  end

  def test_slim_select_group_leaves_a_callers_aria_label_as_the_only_name
    [
      { "aria-label": "Room" }, { "aria-label" => "Room" },
      { aria: { label: "Room" } }, { "aria" => { "label" => "Room" } }
    ].each do |html|
      document = Capybara.string(builder.slim_select_group(:status, Movie.statuses.to_a, html: html))

      assert document.has_css?("select[aria-label=Room]"), html.inspect
      refute document.has_css?("select[aria-labelledby]"), html.inspect
    end
  end

  def test_slim_select_group_leaves_a_callers_aria_labelledby_alone
    result = builder.slim_select_group(:status, Movie.statuses.to_a,
                                       html: { aria: { labelledby: "rooms-heading" } })

    assert_html(result, "select[aria-labelledby=rooms-heading]")
    assert_equal 1, result.scan("aria-labelledby=").size, "aria-labelledby written twice"
  end

  def test_slim_select_group_without_a_caption_points_at_nothing
    result = builder.slim_select_group(:status, Movie.statuses.to_a, label: false)

    refute_html(result, "label")
    refute_html(result, "select[aria-labelledby]")
  end

  def test_slim_select_field_has_no_caption_to_point_at
    result = builder.slim_select_field(:status, Movie.statuses.to_a)

    refute_html(result, "select[aria-labelledby]")
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
    assert_html(result, "p.text-soft-error")
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

  # `multiple:` written at the top level, next to `label:`, used to be discarded in silence:
  # `build_html_options` always seeded `multiple: false` on the element, and Rails copies a
  # top-level `:multiple` onto the element only when the element does not carry the key.
  # The select came out single-valued and nothing said so, while the very same spelling
  # works on `select_group` (#1123). The seed now yields to either hash.
  def test_a_top_level_multiple_reaches_the_select
    result = builder.slim_select_group(:status, Movie.statuses.to_a, multiple: true)
    assert_html(result, 'select[multiple="multiple"][name="movie[status][]"]')
  end

  def test_a_top_level_multiple_reaches_the_select_on_the_bare_field_too
    result = builder.slim_select_field(:status, Movie.statuses.to_a, multiple: true)
    assert_html(result, 'select[multiple="multiple"][name="movie[status][]"]')
  end

  # `html:` is the more specific hash and still wins when both are written.
  def test_the_html_hash_wins_over_a_top_level_multiple
    result = builder.slim_select_field(:status, Movie.statuses.to_a, multiple: true, html: { multiple: false })
    refute_html(result, "select[multiple]")
    assert_html(result, 'select[name="movie[status]"]')
  end

  def test_a_select_without_multiple_anywhere_stays_single_valued
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    refute_html(result, "select[multiple]")
    assert_html(result, 'select[name="movie[status]"]')
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

  # `TEXT_KEYS` looks its keys up at runtime, which `i18n_usage_test.rb` — it reads only
  # literal `t("…")` calls — cannot see.
  def test_every_slim_select_text_key_exists_in_both_locales
    missing = %i[en es].flat_map do |locale|
      Bali::FormBuilder::SlimSelectFields::TEXT_KEYS.values.filter_map do |key|
        exists = I18n.exists?(key, locale, scope: "bali_view.form_builder.slim_select", fallback: false)
        "#{locale}: #{key}" unless exists
      end
    end

    assert_equal [], missing
  end

  # The English defaults are SlimSelect's own `maxValuesMessage` and `addableText`, word for
  # word, so an English host reads what it read before #1232.
  def test_slim_select_field_max_values_message_defaults_to_slim_selects_own_text
    result = builder.slim_select_field(:status, Movie.statuses.to_a)
    assert_html(result, 'div[data-slim-select-max-values-message-value="{number} selected"]')
  end

  def test_slim_select_field_max_values_message_default_is_translated
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a)
      assert_html(result, 'div[data-slim-select-max-values-message-value="{number} seleccionados"]')
    end
  end

  def test_slim_select_field_max_values_message_option_wins_over_the_translated_default
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a, max_values_message: "{number} salas")
      assert_html(result, 'div[data-slim-select-max-values-message-value="{number} salas"]')
    end
  end

  def test_slim_select_field_addable_text_defaults_to_slim_selects_own_text
    result = builder.slim_select_field(:status, Movie.statuses.to_a, add_items: true)
    assert_html(result, %(div[data-slim-select-addable-text-value='Press "Enter" to add {value}']))
  end

  def test_slim_select_field_addable_text_default_is_translated
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a, add_items: true)
      assert_html(result, %(div[data-slim-select-addable-text-value='Presiona "Enter" para agregar {value}']))
    end
  end

  def test_slim_select_field_addable_text_option_wins_over_the_translated_default
    result = builder.slim_select_field(:status, Movie.statuses.to_a, add_items: true,
                                                                     addable_text: "Create {value}")
    assert_html(result, 'div[data-slim-select-addable-text-value="Create {value}"]')
  end

  # What SlimSelect reads out from 3.5 on — the clear button and each tag's remove button —
  # and, from 3.6, the count of results in its live region. Until now always in English.
  def test_slim_select_field_announcements_are_translated
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a)
      assert_html(result, 'div[data-slim-select-deselect-text-value="Borrar selección"]')
      assert_html(result, 'div[data-slim-select-remove-text-value="Quitar"]')
      assert_html(result, 'div[data-slim-select-results-count-text-value="{count} resultados disponibles"]')
    end
  end

  def test_slim_select_field_ajax_placeholder_default_is_translated
    I18n.with_locale(:es) do
      result = builder.slim_select_field(:status, Movie.statuses.to_a, ajax_url: "/api/search")
      assert_html(result, 'div[data-slim-select-ajax-placeholder-value="Escribe al menos 2 caracteres para buscar..."]')
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

  # #1084: what the remote search sends besides the term. Both travel as JSON in the data attribute
  # because Stimulus' value is an Object.
  def test_slim_select_field_ajax_extra_params_travel_as_json
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_url: "/api/search",
                                       ajax_extra_params: { scope: "active", source: "bali" })

    assert_html(result,
                'div[data-slim-select-ajax-extra-params-value=\'{"scope":"active","source":"bali"}\']')
  end

  def test_slim_select_field_ajax_param_selectors_travel_as_json
    result = builder.slim_select_field(:status, Movie.statuses.to_a,
                                       ajax_url: "/api/search",
                                       ajax_param_selectors: { type: "#assignable_type" })

    assert_html(result,
                'div[data-slim-select-ajax-param-selectors-value=\'{"type":"#assignable_type"}\']')
  end

  # A data attribute with "null" inside is not the same as not having the attribute: Stimulus' value
  # would parse it and the `{}` default would not apply.
  def test_slim_select_field_omits_the_extra_ajax_params_when_not_provided
    result = builder.slim_select_field(:status, Movie.statuses.to_a, ajax_url: "/api/search")

    refute_match(/data-slim-select-ajax-extra-params-value/, result)
    refute_match(/data-slim-select-ajax-param-selectors-value/, result)
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
