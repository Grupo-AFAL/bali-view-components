# frozen_string_literal: true

require "test_helper"

class BaliFieldGroupWrapperComponentTest < FormBuilderTestCase
  def setup
    @builder = builder
  end

  #

  def test_rendering_renders_a_fieldset_wrapper_with_daisyui_fieldset_classes
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name)) { "input content" }
    assert_selector("fieldset#field-name.fieldset.w-full")
  end

  def test_rendering_renders_the_block_content
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name)) { '<input type="text" />'.html_safe }
    assert_selector('fieldset#field-name input[type="text"]')
  end
  #

  def test_legend_label_renders_a_legend_by_default
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name)) { "input" }
    assert_selector("legend.fieldset-legend", text: "Name")
  end

  def test_legend_label_accepts_custom_label_text_as_a_string
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: "Custom Label")) { "input" }
    assert_selector("legend.fieldset-legend", text: "Custom Label")
  end

  def test_legend_label_accepts_custom_label_text_as_a_hash_option
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: { text: "Hash Label" })) { "input" }
    assert_selector("legend.fieldset-legend", text: "Hash Label")
  end

  def test_legend_label_hides_legend_when_label_false
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: false)) { "input" }
    assert_no_selector("legend")
  end

  def test_legend_label_hides_legend_when_label_text_false
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: { text: false })) { "input" }
    assert_no_selector("legend")
  end

  def test_legend_label_hides_legend_for_hidden_field_type
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, type: "hidden")) { "input" }
    assert_no_selector("legend")
  end
  #

  def test_tooltip_renders_tooltip_with_info_icon_when_tooltip_option_provided
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: { tooltip: "Help text" })) do
    "input"
    end
    assert_selector("legend.fieldset-legend")
    assert_text("Name")
  end

  def test_tooltip_combines_custom_label_text_with_tooltip
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: { text: "Email", tooltip: "Required" })) do
    "input"
    end
    assert_text("Email")
  end
  #

  def test_custom_classes_applies_field_class_to_the_wrapper
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, field_class: "max-w-md")) { "input" }
    assert_selector("fieldset#field-name.max-w-md")
  end

  def test_custom_classes_applies_class_option_to_the_wrapper
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, class: "my-custom-class")) { "input" }
    assert_selector("fieldset#field-name.my-custom-class")
  end

  def test_custom_classes_applies_custom_label_class
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, label: { class: "font-bold", tooltip: "tip" })) do
    "input"
    end
    assert_selector("legend.fieldset-legend.font-bold")
  end
  #

  def test_data_attributes_applies_field_data_to_the_wrapper
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, field_data: { testid: "wrapper" })) do
    "input"
    end
    assert_selector('fieldset[data-testid="wrapper"]')
  end
  #

  def test_constants_has_base_classes_constant_for_daisyui_fieldset_pattern
    assert_equal("fieldset w-full", Bali::FieldGroupWrapper::Component::BASE_CLASSES)
  end

  def test_constants_has_legend_classes_constant
    assert_equal("fieldset-legend", Bali::FieldGroupWrapper::Component::LEGEND_CLASSES)
  end

  def test_constants_has_legend_text_classes_constant
    assert_equal("flex items-center gap-2", Bali::FieldGroupWrapper::Component::LEGEND_TEXT_CLASSES)
  end
  #

  def test_options_isolation_does_not_mutate_the_passed_options_hash
    options = { label: "Test", field_class: "custom", field_data: { foo: "bar" } }
    original_keys = options.keys.dup
    render_inline(Bali::FieldGroupWrapper::Component.new(@builder, :name, options)) { "input" }
    assert_equal(original_keys, options.keys)
  end
end
