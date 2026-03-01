# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderSubmitButtonsTest < FormBuilderTestCase
  # SubmitFields constants

  def test_submitfields_constants_defines_button_base_class
    assert_equal "btn", Bali::FormBuilder::SubmitFields::BUTTON_BASE_CLASS
  end

  def test_submitfields_constants_defines_wrapper_class
    assert_equal "inline", Bali::FormBuilder::SubmitFields::WRAPPER_CLASS
  end

  def test_submitfields_constants_defines_submit_actions_class
    assert_equal "submit-actions flex items-center justify-end gap-2 mt-6",
                 Bali::FormBuilder::SubmitFields::SUBMIT_ACTIONS_CLASS
  end

  def test_submitfields_constants_defines_frozen_variants_hash
    assert Bali::FormBuilder::SubmitFields::VARIANTS.frozen?
    variants = Bali::FormBuilder::SubmitFields::VARIANTS
    assert_equal "btn-primary", variants[:primary]
    assert_equal "btn-secondary", variants[:secondary]
    assert_equal "btn-success", variants[:success]
    assert_equal "btn-error", variants[:error]
  end

  def test_submitfields_constants_defines_frozen_sizes_hash
    assert Bali::FormBuilder::SubmitFields::SIZES.frozen?
    sizes = Bali::FormBuilder::SubmitFields::SIZES
    assert_equal "btn-xs", sizes[:xs]
    assert_equal "btn-sm", sizes[:sm]
    assert_equal "btn-lg", sizes[:lg]
  end

  # #submit

  def test_submit_renders_an_inline_div_wrapper
    result = builder.submit("Save")
    assert_html(result, "div.inline")
  end

  def test_submit_renders_a_submit_button_with_default_primary_variant
    result = builder.submit("Save")
    assert_html(result, 'button[type="submit"].btn.btn-primary', text: "Save")
  end

  # variant option

  def test_submit_with_variant_option_applies_secondary_variant
    result = builder.submit("Cancel", variant: :secondary)
    assert_html(result, "button.btn.btn-secondary")
  end

  def test_submit_with_variant_option_applies_success_variant
    result = builder.submit("Complete", variant: :success)
    assert_html(result, "button.btn.btn-success")
  end

  def test_submit_with_variant_option_applies_error_variant
    result = builder.submit("Delete", variant: :error)
    assert_html(result, "button.btn.btn-error")
  end

  def test_submit_with_variant_option_applies_ghost_variant
    result = builder.submit("Skip", variant: :ghost)
    assert_html(result, "button.btn.btn-ghost")
  end

  # size option

  def test_submit_with_size_option_applies_xs_size
    result = builder.submit("Save", size: :xs)
    assert_html(result, "button.btn.btn-xs")
  end

  def test_submit_with_size_option_applies_sm_size
    result = builder.submit("Save", size: :sm)
    assert_html(result, "button.btn.btn-sm")
  end

  def test_submit_with_size_option_applies_lg_size
    result = builder.submit("Save", size: :lg)
    assert_html(result, "button.btn.btn-lg")
  end

  def test_submit_with_size_option_applies_no_size_class_for_md_default
    result = builder.submit("Save", size: :md)
    assert_html(result, "button.btn")
    refute_html(result, "button.btn-md")
  end

  # custom wrapper_class

  def test_submit_with_custom_wrapper_class_uses_the_custom_wrapper_class
    result = builder.submit("Save", wrapper_class: "custom-wrapper")
    assert_html(result, "div.custom-wrapper")
    refute_html(result, "div.inline")
  end

  # custom class

  def test_submit_with_custom_class_appends_the_custom_class
    result = builder.submit("Save", class: "extra-class")
    assert_html(result, "button.btn.btn-primary.extra-class")
  end

  # modal option

  def test_submit_with_modal_option_includes_modal_submit_stimulus_action
    result = builder.submit("Save", modal: true)
    assert_html(result, 'button[data-action*="modal#submit"]')
  end

  # drawer option

  def test_submit_with_drawer_option_includes_drawer_submit_stimulus_action
    result = builder.submit("Save", drawer: true)
    assert_html(result, 'button[data-action*="drawer#submit"]')
  end

  # native_app: true

  def test_submit_when_bali_native_app_is_true_does_not_add_modal_stimulus_action
    original = Bali.native_app
    Bali.native_app = true
    result = builder.submit("Save", modal: true)
    refute_html(result, '[data-action*="modal#submit"]')
  ensure
    Bali.native_app = original
  end

  def test_submit_when_bali_native_app_is_true_does_not_add_drawer_stimulus_action
    original = Bali.native_app
    Bali.native_app = true
    result = builder.submit("Save", drawer: true)
    refute_html(result, '[data-action*="drawer#submit"]')
  ensure
    Bali.native_app = original
  end

  # data attributes

  def test_submit_with_data_attributes_passes_through_data_attributes
    result = builder.submit("Save", data: { testid: "submit-btn" })
    assert_html(result, 'button[data-testid="submit-btn"]')
  end

  # #submit_actions — with cancel_path

  def test_submit_actions_with_cancel_path_and_cancel_options_renders_buttons_within_a_wrapper
    result = builder.submit_actions("Save", cancel_path: "/", cancel_options: { label: "Back" })
    assert_html(result, "div.submit-actions.flex.items-center.justify-end.gap-2")
  end

  def test_submit_actions_with_cancel_path_and_cancel_options_renders_a_cancel_button
    result = builder.submit_actions("Save", cancel_path: "/", cancel_options: { label: "Back" })
    assert_html(result, 'a.btn.btn-secondary[href="/"]', text: "Back")
  end

  def test_submit_actions_with_cancel_path_and_cancel_options_renders_a_submit_button
    result = builder.submit_actions("Save", cancel_path: "/", cancel_options: { label: "Back" })
    assert_html(result, 'button[type="submit"].btn.btn-primary', text: "Save")
  end

  def test_submit_actions_with_cancel_path_and_cancel_options_renders_cancel_before_submit
    result = builder.submit_actions("Save", cancel_path: "/", cancel_options: { label: "Back" })
    doc = Nokogiri::HTML(result)
    wrapper = doc.at_css("div.submit-actions")
    children = wrapper.children.select(&:element?)
    assert_equal "div", children.first.name
    assert children.first.at_css("a")
    assert children.last.at_css("button")
  end

  # without cancel path

  def test_submit_actions_without_cancel_path_renders_only_the_submit_button
    result = builder.submit_actions("Save")
    assert_html(result, 'button[type="submit"]', text: "Save")
    refute_html(result, "a")
  end

  # modal option with cancel_path

  def test_submit_actions_with_modal_option_and_cancel_path_adds_modal_close_action_to_cancel_button
    result = builder.submit_actions("Save", cancel_path: "/", modal: true)
    assert_html(result, 'a[data-action*="modal#close"]')
  end

  def test_submit_actions_with_modal_option_and_cancel_path_adds_modal_submit_action_to_submit_button
    result = builder.submit_actions("Save", cancel_path: "/", modal: true)
    assert_html(result, 'button[data-action*="modal#submit"]')
  end

  # drawer option with cancel_path

  def test_submit_actions_with_drawer_option_and_cancel_path_adds_drawer_close_action_to_cancel_button
    result = builder.submit_actions("Save", cancel_path: "/", drawer: true)
    assert_html(result, 'a[data-action*="drawer#close"]')
  end

  def test_submit_actions_with_drawer_option_and_cancel_path_adds_drawer_submit_action_to_submit_button
    result = builder.submit_actions("Save", cancel_path: "/", drawer: true)
    assert_html(result, 'button[data-action*="drawer#submit"]')
  end

  # modal option only (no cancel_path)

  def test_submit_actions_with_modal_option_only_renders_cancel_button_with_modal_close
    result = builder.submit_actions("Save", modal: true)
    assert_html(result, 'button[data-action*="modal#close"]')
  end

  def test_submit_actions_with_modal_option_only_uses_default_cancel_label
    result = builder.submit_actions("Save", modal: true)
    assert_html(result, "button", text: "Cancel")
  end

  def test_submit_actions_with_modal_option_only_renders_button_with_type_button_to_prevent_form_submission
    result = builder.submit_actions("Save", modal: true)
    assert_html(result, 'button[type="button"]', text: "Cancel")
  end

  # custom field_class

  def test_submit_actions_with_custom_field_class_uses_the_custom_field_class
    result = builder.submit_actions("Save", field_class: "custom-actions")
    assert_html(result, "div.custom-actions")
    refute_html(result, "div.submit-actions")
  end

  # field_id

  def test_submit_actions_with_field_id_sets_the_id_on_the_wrapper
    result = builder.submit_actions("Save", field_id: "form-actions")
    assert_html(result, "div#form-actions")
  end

  # field_data

  def test_submit_actions_with_field_data_sets_data_attributes_on_the_wrapper
    result = builder.submit_actions("Save", field_data: { controller: "form-actions" })
    assert_html(result, 'div[data-controller="form-actions"]')
  end

  # native_app: true + modal

  def test_submit_actions_when_bali_native_app_is_true_and_modal_is_true_does_not_render_cancel_button
    original = Bali.native_app
    Bali.native_app = true
    result = builder.submit_actions("Save", cancel_path: "/", modal: true)
    refute_html(result, "a")
  ensure
    Bali.native_app = original
  end

  def test_submit_actions_when_bali_native_app_is_true_and_modal_is_true_renders_only_submit_button
    original = Bali.native_app
    Bali.native_app = true
    result = builder.submit_actions("Save", cancel_path: "/", modal: true)
    assert_html(result, 'button[type="submit"]', text: "Save")
  ensure
    Bali.native_app = original
  end

  # variant option on submit_actions

  def test_submit_actions_with_variant_option_applies_variant_to_submit_button
    result = builder.submit_actions("Delete", variant: :error)
    assert_html(result, "button.btn.btn-error")
  end
end
