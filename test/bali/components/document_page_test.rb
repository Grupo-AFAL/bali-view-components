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

  def test_renders_split_layout_with_metadata_and_preview
    render_inline(Bali::DocumentPage::Component.new(title: "My Document")) do |page|
      page.with_metadata { "Metadata content" }
      page.with_preview { "Preview content" }
    end
    assert_text("Metadata content")
    assert_text("Preview content")
    assert_selector(".document-page-component .grid")
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
end
