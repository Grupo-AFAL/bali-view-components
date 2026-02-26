# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderSearchFieldsTest < FormBuilderTestCase
  # #search_field_group

  def test_search_field_group_renders_a_fieldset_wrapper
    result = builder.search_field_group(:name)
    assert_html(result, "fieldset.fieldset")
  end

  def test_search_field_group_renders_a_legend_label
    result = builder.search_field_group(:name)
    assert_html(result, "legend.fieldset-legend", text: "Name")
  end

  def test_search_field_group_renders_a_text_input_with_correct_attributes
    result = builder.search_field_group(:name)
    assert_html(result, 'input#movie_name[type="text"][name="movie[name]"]')
  end

  def test_search_field_group_applies_daisyui_input_classes
    result = builder.search_field_group(:name)
    assert_html(result, "input.input.input-bordered")
  end

  def test_search_field_group_renders_default_placeholder_from_i18n
    result = builder.search_field_group(:name)
    assert_html(result, 'input[placeholder="Search..."]')
  end

  def test_search_field_group_renders_within_a_join_container_for_addon
    result = builder.search_field_group(:name)
    assert_html(result, "div.join")
  end

  def test_search_field_group_applies_join_item_class_to_input
    result = builder.search_field_group(:name)
    assert_html(result, "input.input.join-item")
  end

  def test_search_field_group_renders_a_submit_button_addon
    result = builder.search_field_group(:name)
    assert_html(result, 'button[type="submit"]')
  end

  def test_search_field_group_renders_search_icon_in_the_button
    result = builder.search_field_group(:name)
    assert_html(result, "button span.icon-component")
  end

  def test_search_field_group_applies_default_button_classes
    result = builder.search_field_group(:name)
    assert_html(result, "button.btn.btn-neutral")
  end

  def test_search_field_group_with_custom_placeholder_uses_custom_placeholder
    result = builder.search_field_group(:name, placeholder: "Find movies...")
    assert_html(result, 'input[placeholder="Find movies..."]')
  end

  def test_search_field_group_with_custom_addon_class_applies_custom_button_classes
    result = builder.search_field_group(:name, addon_class: "btn btn-primary")
    assert_html(result, "button.btn.btn-primary")
  end

  def test_search_field_group_with_custom_addon_class_does_not_apply_default_btn_neutral_class
    result = builder.search_field_group(:name, addon_class: "btn btn-primary")
    refute_html(result, "button.btn-neutral")
  end

  def test_search_field_group_with_validation_errors_applies_error_class_to_input
    resource.errors.add(:name, "is required")
    result = builder.search_field_group(:name)
    assert_html(result, "input.input.input-error")
  end

  def test_search_field_group_with_validation_errors_displays_error_message
    resource.errors.add(:name, "is required")
    result = builder.search_field_group(:name)
    assert_html(result, "p.text-error", text: "Name is required")
  end

  def test_search_field_group_with_custom_class_includes_custom_class_with_daisyui_classes
    result = builder.search_field_group(:name, class: "custom-search")
    assert_html(result, "input.input.input-bordered.custom-search")
  end

  def test_search_field_group_with_data_attributes_passes_through_data_attributes
    result = builder.search_field_group(:name, data: { testid: "search-input" })
    assert_html(result, 'input.input[data-testid="search-input"]')
  end

  def test_search_field_group_with_required_attribute_renders_required_input
    result = builder.search_field_group(:name, required: true)
    assert_html(result, "input[required]")
  end

  def test_search_field_group_with_disabled_attribute_renders_disabled_input
    result = builder.search_field_group(:name, disabled: true)
    assert_html(result, "input[disabled]")
  end

  # DEFAULT_BUTTON_CLASSES constant

  def test_default_button_classes_constant_is_defined
    assert_equal("btn btn-neutral", Bali::FormBuilder::SearchFields::DEFAULT_BUTTON_CLASSES)
  end

  def test_default_button_classes_constant_is_frozen
    assert(Bali::FormBuilder::SearchFields::DEFAULT_BUTTON_CLASSES.frozen?)
  end
end
