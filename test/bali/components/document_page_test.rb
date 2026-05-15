# frozen_string_literal: true

require "test_helper"

class BaliDocumentPageComponentTest < ComponentTestCase
  def test_renders_with_title
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_preview { "Document content preview" }
    end
    assert_text("My Document")
    assert_text("Document content preview")
  end

  def test_renders_breadcrumbs
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      breadcrumbs: [
        { name: "Dashboard", href: "/" },
        { name: "Documents", href: "/documents" },
        { name: "My Document" }
      ]
    )) do |page|
      page.with_preview { "Content" }
    end
    assert_selector(".breadcrumbs")
  end

  def test_renders_actions
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_action { "Edit Button" }
      page.with_preview { "Content" }
    end
    assert_text("Edit Button")
  end

  def test_renders_subtitle
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      subtitle: "Last edited 2 hours ago"
    )) do |page|
      page.with_preview { "Content" }
    end
    assert_text("Last edited 2 hours ago")
  end

  def test_renders_back_button
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      back: { href: "/documents" }
    )) do |page|
      page.with_preview { "Content" }
    end
    assert_selector("a[href='/documents']")
  end

  def test_renders_title_tags
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_title_tag { "Draft" }
      page.with_preview { "Content" }
    end
    assert_text("Draft")
  end

  def test_renders_stimulus_controller
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_preview { "Content" }
    end
    assert_selector("[data-controller='document-page']")
  end

  def test_renders_three_panel_layout_with_metadata
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Metadata content" }
      page.with_preview { "Preview content" }
    end
    assert_text("Metadata content")
    assert_text("Preview content")
    assert_selector("[data-document-page-target='metadataPanel']")
    assert_selector("[data-action='document-page#toggleMetadata']")
  end

  def test_renders_metadata_toggle_in_header
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Metadata" }
      page.with_preview { "Content" }
    end
    assert_selector("[data-document-page-target='metadataToggle']")
  end

  def test_no_toggles_without_panels
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_preview { "Content" }
    end
    assert_no_selector("[data-action='document-page#toggleToc']")
    assert_no_selector("[data-action='document-page#toggleMetadata']")
  end

  def test_renders_simple_layout_without_metadata
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_preview { "Just preview" }
    end
    assert_text("Just preview")
    assert_no_selector("[data-document-page-target='metadataPanel']")
  end

  def test_accepts_custom_classes_via_options
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      class: "custom-page"
    )) do |page|
      page.with_preview { "Content" }
    end
    assert_selector(".document-page-component.custom-page")
  end

  def test_accepts_data_attributes_via_options
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      id: "my-page"
    )) do |page|
      page.with_preview { "Content" }
    end
    assert_selector("#my-page.document-page-component")
  end

  def test_toc_panel_defaults_open
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector("[data-document-page-toc-open-value='true']")
  end

  def test_toc_panel_can_default_closed
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json,
      toc_open: false
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector("[data-document-page-toc-open-value='false']")
  end

  def test_metadata_panel_defaults_open
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Meta" }
      page.with_preview { "Content" }
    end
    assert_selector("[data-document-page-metadata-open-value='true']")
  end

  def test_metadata_panel_can_default_closed
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      metadata_open: false
    )) do |page|
      page.with_metadata { "Meta" }
      page.with_preview { "Content" }
    end
    assert_selector("[data-document-page-metadata-open-value='false']")
  end

  def test_renders_toc_panel_with_block_editor_content
    render_inline(Bali::DocumentPage::Component.new(
      title: "My Document",
      initial_content: [ { type: "paragraph", content: [ { type: "text", text: "Hello" } ] } ].to_json
    )) do |page|
      page.with_metadata { "Meta" }
    end
    assert_selector("[data-document-page-target='tocPanel']")
    assert_selector("#document-page-toc-container")
    assert_selector("[data-action='document-page#toggleToc']")
  end

  def test_no_toc_without_initial_content
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Meta" }
      page.with_preview { "Content" }
    end
    assert_no_selector("[data-document-page-target='tocPanel']")
    assert_no_selector("[data-action='document-page#toggleToc']")
  end

  def test_falls_back_to_content_slot_without_preview_or_initial_content
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) { "Fallback content" }
    assert_text("Fallback content")
  end
end
