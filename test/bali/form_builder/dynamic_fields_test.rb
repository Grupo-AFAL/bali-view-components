# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderDynamicFieldsConstantsTest < FormBuilderTestCase
  # Bali::FormBuilder::DynamicFields constants

  def test_defines_header_class
    assert_equal("flex justify-between items-center", Bali::FormBuilder::DynamicFields::HEADER_CLASS)
  end

  def test_defines_label_wrapper_class
    assert_equal("flex items-center", Bali::FormBuilder::DynamicFields::LABEL_WRAPPER_CLASS)
  end

  def test_defines_label_class
    assert_equal("label", Bali::FormBuilder::DynamicFields::LABEL_CLASS)
  end

  def test_defines_button_wrapper_class
    assert_equal("flex items-center", Bali::FormBuilder::DynamicFields::BUTTON_WRAPPER_CLASS)
  end

  def test_defines_default_button_class
    assert_equal("btn btn-primary", Bali::FormBuilder::DynamicFields::DEFAULT_BUTTON_CLASS)
  end

  def test_defines_destroy_flag_class
    assert_equal("destroy-flag", Bali::FormBuilder::DynamicFields::DESTROY_FLAG_CLASS)
  end

  def test_defines_controller_name
    assert_equal("dynamic-fields", Bali::FormBuilder::DynamicFields::CONTROLLER_NAME)
  end

  def test_defines_child_index_placeholder
    assert_equal("new_record", Bali::FormBuilder::DynamicFields::CHILD_INDEX_PLACEHOLDER)
  end

  def test_freezes_all_css_class_constants
    assert(Bali::FormBuilder::DynamicFields::HEADER_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::LABEL_WRAPPER_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::LABEL_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::BUTTON_WRAPPER_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::DEFAULT_BUTTON_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::DESTROY_FLAG_CLASS.frozen?)
    assert(Bali::FormBuilder::DynamicFields::CONTROLLER_NAME.frozen?)
    assert(Bali::FormBuilder::DynamicFields::CHILD_INDEX_PLACEHOLDER.frozen?)
  end
end

class BaliFormBuilderLinkToRemoveFieldsTest < FormBuilderTestCase
  # #link_to_remove_fields

  def test_renders_a_link_element
    result = builder.link_to_remove_fields("Remove")
    assert_includes(result, ">Remove<")
  end

  def test_includes_href_on_the_link
    assert_includes(builder.link_to_remove_fields("Remove"), 'href="#"')
  end

  def test_adds_stimulus_action_for_removing_fields
    assert_includes(builder.link_to_remove_fields("Remove"), "dynamic-fields#removeFields")
  end

  def test_renders_a_hidden_field_for_destroy
    assert_includes(builder.link_to_remove_fields("Remove"), "_destroy")
  end

  def test_applies_destroy_flag_class_to_hidden_field
    assert_includes(builder.link_to_remove_fields("Remove"), "destroy-flag")
  end
  # with custom class

  def test_with_custom_class_applies_custom_class_to_link
    result = builder.link_to_remove_fields("Remove", class: "btn btn-error")
    assert_includes(result, "btn-error")
  end
  # with data attributes

  def test_with_data_attributes_passes_through_data_attributes
    result = builder.link_to_remove_fields("Remove", data: { testid: "remove-btn" })
    assert_includes(result, 'data-testid="remove-btn"')
  end

  def test_with_data_attributes_merges_action_with_existing_data
    result = builder.link_to_remove_fields("Remove", data: { testid: "remove-btn" })
    assert_includes(result, "dynamic-fields#removeFields")
  end
  # with soft_delete: true

  def test_with_soft_delete_true_renders_hidden_field_for_soft_delete_instead_of_destroy
    soft_delete_resource = Movie.new
    soft_delete_resource.define_singleton_method(:_soft_delete) { nil }
    soft_delete_builder = movie_form_builder(soft_delete_resource)
    result = soft_delete_builder.link_to_remove_fields("Remove", soft_delete: true)
    assert_includes(result, "_soft_delete")
  end

  def test_with_soft_delete_true_does_not_render_destroy_hidden_field
    soft_delete_resource = Movie.new
    soft_delete_resource.define_singleton_method(:_soft_delete) { nil }
    soft_delete_builder = movie_form_builder(soft_delete_resource)
    result = soft_delete_builder.link_to_remove_fields("Remove", soft_delete: true)
    refute_includes(result, "_destroy")
  end
  # with soft_delete: false

  def test_with_soft_delete_false_renders_hidden_field_for_destroy
    result = builder.link_to_remove_fields("Remove", soft_delete: false)
    assert_includes(result, "_destroy")
  end
end

class BaliFormBuilderDynamicFieldsGroupTest < FormBuilderTestCase
  # TODO: Add tests for #dynamic_fields_group (requires mocha for association mocking)
end

class BaliFormBuilderLinkToAddFieldsTest < FormBuilderTestCase
  # TODO: Add tests for #link_to_add_fields (requires mocha for association reflection mocking)
end
