# frozen_string_literal: true

require "test_helper"

class BaliShowPageComponentTest < ComponentTestCase
  def test_renders_page_with_title
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_body { "Movie details" }
    end
    assert_text("The Matrix")
    assert_text("Movie details")
  end

  def test_renders_breadcrumbs
    render_inline(Bali::ShowPage::Component.new(
      title: "The Matrix",
      breadcrumbs: [
        { name: "Dashboard", href: "/" },
        { name: "Movies", href: "/movies" },
        { name: "The Matrix" }
      ]
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector(".breadcrumbs")
  end

  def test_renders_back_button
    render_inline(Bali::ShowPage::Component.new(
      title: "The Matrix",
      back: { href: "/movies" }
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector("a[href='/movies']")
  end

  def test_renders_two_column_layout_with_sidebar
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_body { "Main content" }
      page.with_sidebar { "Sidebar content" }
    end
    assert_text("Main content")
    assert_text("Sidebar content")
  end

  def test_renders_full_width_without_sidebar
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_body { "Full width content" }
    end
    assert_text("Full width content")
    assert_no_selector(".show-page-sidebar")
  end

  def test_renders_title_tags
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_title_tag { "Action" }
      page.with_title_tag { "Sci-Fi" }
      page.with_body { "Content" }
    end
    assert_text("Action")
    assert_text("Sci-Fi")
  end

  def test_renders_actions
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_action { "Edit Button" }
      page.with_body { "Content" }
    end
    assert_text("Edit Button")
  end
end
