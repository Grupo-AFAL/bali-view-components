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

  def test_actions_bar_stacks_full_width_on_mobile
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_action { "Edit Button" }
      page.with_body { "Content" }
    end
    assert_selector(".max-sm\\:w-full", text: "Edit Button")
  end

  def test_renders_nav_between_header_and_body
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_nav { page.tag.a("Subnav link", href: "/movies/1/reviews") }
      page.with_body { "Movie details" }
    end
    assert_selector(".page-nav.mt-4 a[href='/movies/1/reviews']", text: "Subnav link")

    html = page.native.to_html
    assert_operator html.index("The Matrix"), :<, html.index("Subnav link")
    assert_operator html.index("Subnav link"), :<, html.index("Movie details")
  end

  def test_does_not_render_nav_wrapper_without_nav
    render_inline(Bali::ShowPage::Component.new(title: "The Matrix")) do |page|
      page.with_body { "Content" }
    end
    assert_no_selector(".page-nav")
  end
end
