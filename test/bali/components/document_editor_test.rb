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
      comments: { url: "/block_editor_comments", user: { id: "1", username: "demo" } }
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
      comments: { url: "/comments", user: { id: "1", username: "demo" } }
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
      export: true
    ))
    assert_selector("[data-action='document-editor#exportPdf']")
    assert_selector("[data-action='document-editor#exportDocx']")
  end

  def test_no_export_dropdown_when_export_disabled
    render_inline(Bali::DocumentEditor::Component.new(
      title: "My Document",
      initial_content: [],
      document_url: "/documents/1",
      export: false
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
    assert_selector("#document-editor-toc-container")
  end
end
