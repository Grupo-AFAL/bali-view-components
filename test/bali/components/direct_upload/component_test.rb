# frozen_string_literal: true

require "test_helper"

class BaliDirectUploadComponentTest < ActionView::TestCase
  include ViewComponent::TestHelpers
  include Capybara::Minitest::Assertions

  def render_component(**opts)
    form_with(model: Movie.new, url: "/movies") do |form|
      render_inline(Bali::DirectUpload::Component.new(form: form, method: :attachment, **opts))
    end
  end

  # Default rendering

  def test_default_rendering_renders_container_with_direct_upload_controller
    render_component
    assert_selector('.direct-upload-component[data-controller="direct-upload"]')
  end


  def test_default_rendering_renders_hidden_file_input
    render_component
    assert_selector('input[type="file"].hidden', visible: :all)
  end


  def test_default_rendering_renders_drop_zone_by_default
    render_component
    assert_selector('[data-direct-upload-target="dropzone"]')
  end


  def test_default_rendering_renders_browse_button
    render_component
    assert_selector(".btn", text: "Browse Files")
  end


  def test_default_rendering_renders_file_list_container
    render_component
    assert_selector('[data-direct-upload-target="fileList"]')
  end


  def test_default_rendering_renders_hidden_fields_container
    render_component
    assert_selector('[data-direct-upload-target="hiddenFields"]')
  end


  def test_default_rendering_renders_template_for_file_items
    render_component
    assert_selector('template[data-direct-upload-target="template"]', visible: :all)
  end

  # Stimulus data values

  def test_stimulus_data_values_sets_url_value_to_rails_direct_uploads_path
    render_component
    assert_selector("[data-direct-upload-url-value]")
  end


  def test_stimulus_data_values_sets_multiple_value_to_false_by_default
    render_component
    assert_selector('[data-direct-upload-multiple-value="false"]')
  end


  def test_stimulus_data_values_sets_max_files_value_to_10_by_default
    render_component
    assert_selector('[data-direct-upload-max-files-value="10"]')
  end


  def test_stimulus_data_values_sets_max_file_size_value_to_10_by_default
    render_component
    assert_selector('[data-direct-upload-max-file-size-value="10"]')
  end


  def test_stimulus_data_values_sets_accept_value_to_by_default
    render_component
    assert_selector('[data-direct-upload-accept-value="*"]')
  end


  def test_stimulus_data_values_sets_auto_upload_value_to_true_by_default
    render_component
    assert_selector('[data-direct-upload-auto-upload-value="true"]')
  end


  def test_stimulus_data_values_sets_field_name_value_based_on_form_object
    render_component
    assert_selector("[data-direct-upload-field-name-value]")
  end

  # Multiple file mode

  def test_multiple_file_mode_sets_multiple_value_to_true
    render_component(multiple: true)
    assert_selector('[data-direct-upload-multiple-value="true"]')
  end


  def test_multiple_file_mode_sets_multiple_attribute_on_file_input
    render_component(multiple: true)
    assert_selector('input[type="file"][multiple]', visible: :all)
  end


  def test_multiple_file_mode_appends_to_field_name
    render_component(multiple: true)
    assert_selector('[data-direct-upload-field-name-value*="[]"]')
  end

  # Configuration

  def test_max_files_configuration_sets_custom_max_files_value
    render_component(max_files: 5)
    assert_selector('[data-direct-upload-max-files-value="5"]')
  end


  def test_max_file_size_configuration_sets_custom_max_file_size_value
    render_component(max_file_size: 20)
    assert_selector('[data-direct-upload-max-file-size-value="20"]')
  end


  def test_accept_filter_configuration_sets_custom_accept_value
    render_component(accept: "image/*,.pdf")
    assert_selector('[data-direct-upload-accept-value="image/*,.pdf"]')
  end


  def test_accept_filter_configuration_sets_accept_attribute_on_file_input
    render_component(accept: "image/*,.pdf")
    assert_selector('input[type="file"][accept="image/*,.pdf"]', visible: :all)
  end

  # Without drop zone

  def test_without_drop_zone_does_not_render_drop_zone
    render_component(drop_zone: false)
    assert_no_selector('[data-direct-upload-target="dropzone"]')
  end


  def test_without_drop_zone_renders_browse_button
    render_component(drop_zone: false)
    assert_selector("button.btn", text: "Browse Files")
  end


  def test_without_drop_zone_browse_button_has_open_file_picker_action
    render_component(drop_zone: false)
    assert_selector('button[data-action="direct-upload#openFilePicker"]')
  end

  # Auto upload

  def test_auto_upload_configuration_sets_auto_upload_value_to_false
    render_component(auto_upload: false)
    assert_selector('[data-direct-upload-auto-upload-value="false"]')
  end

  # Drop zone interactions

  def test_drop_zone_interactions_has_drag_and_drop_event_handlers
    render_component
    dropzone = page.find('[data-direct-upload-target="dropzone"]')
    assert_includes(dropzone["data-action"], "dragenter->direct-upload#dragenter")
    assert_includes(dropzone["data-action"], "dragover->direct-upload#dragover")
    assert_includes(dropzone["data-action"], "dragleave->direct-upload#dragleave")
    assert_includes(dropzone["data-action"], "drop->direct-upload#drop")
  end


  def test_drop_zone_interactions_has_click_handler_to_open_file_picker
    render_component
    dropzone = page.find('[data-direct-upload-target="dropzone"]')
    assert_includes(dropzone["data-action"], "click->direct-upload#openFilePicker")
  end

  # File input attributes

  def test_file_input_attributes_has_input_target
    render_component
    assert_selector('input[data-direct-upload-target="input"]', visible: :all)
  end


  def test_file_input_attributes_has_select_files_action
    render_component
    assert_selector('input[data-action*="direct-upload#selectFiles"]', visible: :all)
  end

  # Template structure

  def test_template_structure_template_element_exists
    render_component
    assert_selector('template[data-direct-upload-target="template"]', visible: :all)
  end

  # Custom classes

  def test_custom_classes_allows_custom_classes
    render_component(class: "my-custom-class")
    assert_selector(".direct-upload-component.my-custom-class")
  end

  # Accessibility

  def test_accessibility_renders_dropzone_with_role_button_and_tabindex
    render_component
    dropzone = page.find('[data-direct-upload-target="dropzone"]')
    assert_equal("button", dropzone["role"])
    assert_equal("0", dropzone["tabindex"])
  end


  def test_accessibility_renders_dropzone_with_aria_label
    render_component
    assert_selector('[data-direct-upload-target="dropzone"][aria-label]')
  end


  def test_accessibility_renders_file_list_with_role_list_and_aria_label
    render_component
    file_list = page.find('[data-direct-upload-target="fileList"]')
    assert_equal("list", file_list["role"])
    assert(file_list["aria-label"].present?)
  end


  def test_accessibility_renders_announcer_live_region_for_screen_readers
    render_component
    announcer = page.find('[data-direct-upload-target="announcer"]', visible: :all)
    assert_equal("status", announcer["role"])
    assert_equal("polite", announcer["aria-live"])
    assert_includes(announcer.native["class"], "sr-only")
  end


  def test_accessibility_has_keyboard_support_handler_on_dropzone
    render_component
    dropzone = page.find('[data-direct-upload-target="dropzone"]')
    assert_includes(dropzone["data-action"], "keydown->direct-upload#dropzoneKeydown")
  end

  # Error alert

  def test_error_alert_renders_error_alert_container
    render_component
    assert_selector('[data-direct-upload-target="errorAlert"].alert.alert-error.hidden', visible: :all)
  end


  def test_error_alert_renders_error_message_container
    render_component
    assert_selector('[data-direct-upload-target="errorMessage"]', visible: :all)
  end


  def test_error_alert_renders_dismiss_button_with_action
    render_component
    assert_selector('[data-action="direct-upload#dismissError"]', visible: :all)
  end

  # Remove field name

  def test_remove_field_name_value_sets_remove_field_name_value
    render_component
    assert_selector("[data-direct-upload-remove-field-name-value]")
  end


  def test_remove_field_name_value_remove_field_name_includes_the_method_name
    render_component
    container = page.find(".direct-upload-component")
    assert_includes(container["data-direct-upload-remove-field-name-value"], "remove_attachment")
  end

  # Remove fields container

  def test_remove_fields_container_renders_remove_fields_container
    render_component
    assert_selector('[data-direct-upload-target="removeFields"]', visible: :all)
  end
end
