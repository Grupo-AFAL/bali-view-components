# frozen_string_literal: true

require "test_helper"

class BaliDocumentEditorComponentTest < ComponentTestCase
  def test_renders_overlay_container
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-controller='document-editor']")
    assert_selector(".document-editor-overlay")
  end

  def test_renders_app_bar_with_title
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector(".document-editor-app-bar")
    assert_selector("input[value='My Document']")
  end

  def test_renders_close_button
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      close_url: "/documents/1"
    ))
    assert_selector("a[href='/documents/1']")
  end

  def test_renders_toc_toggle
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-action*='document-editor#toggleToc']")
  end

  def test_renders_comments_toggle_when_comments_configured
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { comments: { url: "/block_editor_comments", user: { id: "1", username: "demo" } } }
    ))
    assert_selector("[data-action*='document-editor#toggleComments']")
  end

  def test_no_comments_toggle_without_config
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-action*='document-editor#toggleComments']")
  end

  def test_renders_history_toggle_when_versions_url_present
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: "/documents/1/versions"
    ))
    assert_selector("[data-action*='document-editor#toggleHistory']")
  end

  def test_no_history_toggle_without_versions_url
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-action*='document-editor#toggleHistory']")
  end

  def test_renders_in_readonly_mode
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      editable: false
    ))
    assert_selector(".document-editor-overlay")
    assert_no_selector("input[data-document-editor-target='titleInput']")
  end

  def test_renders_editable_title_input
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      editable: true
    ))
    assert_selector("input[data-document-editor-target='titleInput']")
  end

  def test_renders_auto_save_values
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      auto_save: true,
      auto_save_delay: 5000
    ))
    assert_selector("[data-document-editor-auto-save-value='true']")
    assert_selector("[data-document-editor-auto-save-delay-value='5000']")
  end

  def test_defaults_close_url_to_document_url
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("a[href='/documents/1'][data-action='document-editor#close']")
  end

  def test_renders_editor_content_area
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector(".document-editor-overlay .flex-1.overflow-y-auto")
  end

  def test_renders_comments_panel_when_configured
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { comments: { url: "/comments", user: { id: "1", username: "demo" } } }
    ))
    assert_selector("[data-document-editor-target='commentsPanel']")
    assert_text("Comments")
  end

  def test_no_comments_panel_without_config
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-document-editor-target='commentsPanel']")
  end

  def test_renders_history_panel_when_versions_url_present
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      versions_url: "/documents/1/versions"
    ))
    assert_selector("[data-document-editor-target='historyPanel']")
    assert_text("Version History")
  end

  def test_no_history_panel_without_versions_url
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_no_selector("[data-document-editor-target='historyPanel']")
  end

  def test_renders_readonly_title_as_heading
    render_inline(Bali::DocumentEditor::Component.new(
      title: "Read Only Doc",
      initial_content: [],
      document_url: "/documents/1",
      editable: false
    ))
    assert_selector("h1", text: "Read Only Doc")
  end

  def test_renders_export_dropdown_when_export_enabled
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: true }
    ))
    assert_selector("[data-action='document-editor#exportPdf']")
    assert_selector("[data-action='document-editor#exportDocx']")
  end

  def test_no_export_dropdown_when_export_disabled
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: false }
    ))
    assert_no_selector("[data-action='document-editor#exportPdf']")
  end

  def test_renders_toc_panel_with_portal_container
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-target='tocPanel']")
    assert_selector("[id^='document-editor-toc-']")
  end

  def test_passes_custom_input_name_to_controller
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      input_name: "article[body]"
    ))
    assert_selector("[data-document-editor-input-name-value='article[body]']")
  end

  def test_defaults_input_name_to_document_content
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-input-name-value='document[content]']")
  end

  def test_accepts_custom_classes_via_options
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      class: "custom-editor"
    ))
    assert_selector(".document-editor-overlay.custom-editor")
  end

  def test_accepts_data_attributes_via_options
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      id: "my-editor"
    ))
    assert_selector("#my-editor.document-editor-overlay")
  end

  # --- REST contract (#700) ---------------------------------------------------

  # The controller used to POST to "#{document_url}/restore_version", a path it
  # invented. It is now a declared value with the same default, so an app whose
  # routes already matched keeps working while one that does not can say so.
  def test_restore_version_url_defaults_to_the_conventional_path
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-restore-version-url-value='/documents/1/restore_version']")
  end

  def test_restore_version_url_can_be_named_by_the_host
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      restore_version_url: "/documents/1/revisions/restore"
    ))
    assert_selector("[data-document-editor-restore-version-url-value='/documents/1/revisions/restore']")
  end

  # The PATCH payload root and the hidden input name both used to hardcode
  # "document", which assumed every host named its model Document.
  def test_param_key_defaults_to_document_and_drives_the_input_name
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1"
    ))
    assert_selector("[data-document-editor-param-key-value='document']")
    assert_selector("[data-document-editor-input-name-value='document[content]']")
  end

  def test_param_key_renames_the_payload_root_and_the_input_name
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/articles/1",
      param_key: :article
    ))
    assert_selector("[data-document-editor-param-key-value='article']")
    assert_selector("[data-document-editor-input-name-value='article[content]']")
  end

  def test_an_explicit_input_name_still_wins_over_the_derived_one
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/articles/1",
      param_key: :article,
      input_name: "article[body]"
    ))
    assert_selector("[data-document-editor-input-name-value='article[body]']")
  end

  # --- Shared config package (#700) -------------------------------------------

  def test_config_reaches_the_nested_block_editor
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { ai_url: "/ai", mentions_url: "/users" }
    ))
    assert_selector("[data-block-editor-ai-url-value='/ai']")
    assert_selector("[data-block-editor-mentions-url-value='/users']")
  end

  def test_config_accepts_a_config_object_as_well_as_a_hash
    config = Bali::BlockEditor::Config.new(ai_url: "/ai")
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      config: config
    ))
    assert_selector("[data-block-editor-ai-url-value='/ai']")
  end

  def test_export_filename_falls_back_to_the_parameterized_title
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Big Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: true }
    ))
    assert_selector("[data-block-editor-export-filename-value='my-big-document']")
  end

  def test_an_export_filename_in_the_config_beats_the_title
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Big Document",
      initial_content: [],
      document_url: "/documents/1",
      config: { export: true, export_filename: "roadmap" }
    ))
    assert_selector("[data-block-editor-export-filename-value='roadmap']")
  end
end
