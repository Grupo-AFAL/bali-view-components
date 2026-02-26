# frozen_string_literal: true

require "test_helper"

class BaliBlockEditorComponentTest < ComponentTestCase
  def setup
    @original_enabled = Bali.block_editor_enabled
    Bali.block_editor_enabled = true
  end


  def teardown
    Bali.block_editor_enabled = @original_enabled
  end


  def test_renders_block_editor_component
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector("div.block-editor-component")
  end

  def test_does_not_render_when_block_editor_enabled_is_false
    Bali.block_editor_enabled = false
    render_inline(Bali::BlockEditor::Component.new)
    assert_no_selector("div.block-editor-component")
  end

  def test_renders_editor_target_container
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-target="editor"]')
  end

  def test_renders_hidden_input_when_input_name_is_provided
    render_inline(Bali::BlockEditor::Component.new(input_name: "post[content]"))
    assert_selector('input[type="hidden"][name="post[content]"]', visible: false)
  end

  def test_does_not_render_hidden_input_when_input_name_is_nil
    render_inline(Bali::BlockEditor::Component.new)
    assert_no_selector('input[type="hidden"][data-block-editor-target="output"]')
  end

  def test_applies_editable_data_value
    render_inline(Bali::BlockEditor::Component.new(editable: true))
    assert_selector('[data-block-editor-editable-value="true"]')
  end

  def test_applies_non_editable_data_value
    render_inline(Bali::BlockEditor::Component.new(editable: false))
    assert_selector('[data-block-editor-editable-value="false"]')
  end

  def test_does_not_render_hidden_input_when_not_editable
    render_inline(Bali::BlockEditor::Component.new(editable: false, input_name: "post[content]"))
    assert_no_selector('input[type="hidden"]', visible: false)
  end

  def test_applies_placeholder_data_value
    render_inline(Bali::BlockEditor::Component.new(placeholder: "Write here..."))
    assert_selector('[data-block-editor-placeholder-value="Write here..."]')
  end

  def test_serializes_hash_content_to_json
    blocks = [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ]
    render_inline(Bali::BlockEditor::Component.new(initial_content: blocks, input_name: "post[content]"))
    input = page.find('input[type="hidden"]', visible: false)
    assert_equal(blocks.to_json, input.value)
  end

  def test_passes_string_content_directly
    json_str = '[{"type":"paragraph"}]'
    render_inline(Bali::BlockEditor::Component.new(initial_content: json_str, input_name: "post[content]"))
    input = page.find('input[type="hidden"]', visible: false)
    assert_equal(json_str, input.value)
  end

  def test_applies_format_data_value
    render_inline(Bali::BlockEditor::Component.new(format: :html))
    assert_selector('[data-block-editor-format-value="html"]')
  end

  def test_applies_custom_css_classes
    render_inline(Bali::BlockEditor::Component.new(class: "custom-class"))
    assert_selector("div.block-editor-component.custom-class")
  end

  def test_sets_controller_data_attribute
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-controller="block-editor"]')
  end

  def test_applies_upload_url_data_value_when_explicitly_set
    render_inline(Bali::BlockEditor::Component.new(upload_url: "/uploads"))
    assert_selector('[data-block-editor-upload-url-value="/uploads"]')
  end

  def test_applies_html_content_data_value
    render_inline(Bali::BlockEditor::Component.new(html_content: "<p>Hello</p>"))
    assert_selector("[data-block-editor-html-content-value]")
  end
  #

  def test_with_auto_upload_url_resolves_from_bali_block_editor_upload_url_config
    original = Bali.block_editor_upload_url
    Bali.block_editor_upload_url = "/bali/block_editor/uploads"
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-upload-url-value="/bali/block_editor/uploads"]')
  ensure
    Bali.block_editor_upload_url = original
  end

  def test_with_auto_upload_url_does_not_set_upload_url_when_not_editable
    original = Bali.block_editor_upload_url
    Bali.block_editor_upload_url = "/bali/block_editor/uploads"
    render_inline(Bali::BlockEditor::Component.new(editable: false))
    assert_no_selector("[data-block-editor-upload-url-value]")
  ensure
    Bali.block_editor_upload_url = original
  end

  def test_with_auto_upload_url_does_not_set_upload_url_when_upload_url_is_nil
    render_inline(Bali::BlockEditor::Component.new(upload_url: nil))
    assert_no_selector("[data-block-editor-upload-url-value]")
  end
  #

  def test_with_table_of_contents_sets_table_of_contents_value_to_false_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-table-of-contents-value="false"]')
  end

  def test_with_table_of_contents_sets_table_of_contents_value_to_true_when_enabled
    render_inline(Bali::BlockEditor::Component.new(table_of_contents: true))
    assert_selector('[data-block-editor-table-of-contents-value="true"]')
  end
  #

  def test_with_comments_sets_comments_value_to_false_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-comments-value="false"]')
  end

  def test_with_comments_sets_comments_value_to_true_when_enabled
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-value="true"]')
  end

  def test_with_comments_serializes_comments_user_as_json
    user = { id: "1", username: "Alice", avatar_url: "" }
    render_inline(Bali::BlockEditor::Component.new(comments: { user: user }))
    assert_selector("[data-block-editor-comments-user-value]")
    el = page.find("[data-block-editor-comments-user-value]")
    parsed = JSON.parse(el[:"data-block-editor-comments-user-value"])
    assert_equal("1", parsed["id"])
    assert_equal("Alice", parsed["username"])
  end

  def test_with_comments_serializes_comments_users_as_json_array
    users = [
    { id: "1", username: "Alice" }, { id: "2", username: "Bob" }
    ]
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" }, users: users }))
    el = page.find("[data-block-editor-comments-users-value]")
    parsed = JSON.parse(el[:"data-block-editor-comments-users-value"])
    assert_kind_of(Array, parsed)
    assert_equal(2, parsed.length)
    assert_equal("Alice", parsed.first["username"])
  end

  def test_with_comments_applies_comments_users_url_data_value
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" }, users_url: "/api/users" }))
    assert_selector('[data-block-editor-comments-users-url-value="/api/users"]')
  end

  def test_with_comments_applies_comments_url_data_value_for_rest_persistence
    render_inline(Bali::BlockEditor::Component.new(comments: { url: "/block_editor_comments", user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-url-value="/block_editor_comments"]')
  end

  def test_with_comments_defaults_comments_url_to_empty_string
    render_inline(Bali::BlockEditor::Component.new(comments: { user: { id: "1", username: "Alice" } }))
    assert_selector('[data-block-editor-comments-url-value=""]')
  end
  #

  def test_export_functionality_does_not_render_export_buttons_by_default
    render_inline(Bali::BlockEditor::Component.new)
    assert_no_selector('[data-action*="exportPdf"]')
    assert_no_selector('[data-action*="exportDocx"]')
  end

  def test_export_functionality_renders_both_export_buttons_when_export_true
    render_inline(Bali::BlockEditor::Component.new(export: true))
    assert_selector('button[data-action="block-editor#exportPdf"]')
    assert_selector('button[data-action="block-editor#exportDocx"]')
    assert_text("Export PDF")
    assert_text("Export DOCX")
  end

  def test_export_functionality_renders_only_pdf_button_when_export_pdf
    render_inline(Bali::BlockEditor::Component.new(export: [ :pdf ]))
    assert_selector('button[data-action="block-editor#exportPdf"]')
    assert_no_selector('[data-action*="exportDocx"]')
  end

  def test_export_functionality_renders_only_docx_button_when_export_docx
    render_inline(Bali::BlockEditor::Component.new(export: [ :docx ]))
    assert_no_selector('[data-action*="exportPdf"]')
    assert_selector('button[data-action="block-editor#exportDocx"]')
  end

  def test_export_functionality_applies_export_filename_data_value
    render_inline(Bali::BlockEditor::Component.new(export_filename: "my-report"))
    assert_selector('[data-block-editor-export-filename-value="my-report"]')
  end

  def test_export_functionality_defaults_export_filename_to_document
    render_inline(Bali::BlockEditor::Component.new)
    assert_selector('[data-block-editor-export-filename-value="document"]')
  end
end
