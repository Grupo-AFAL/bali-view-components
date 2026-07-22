# frozen_string_literal: true

require "test_helper"

class BaliIndexPageComponentTest < ComponentTestCase
  def test_renders_page_with_title
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_body { "Table goes here" }
    end
    assert_text("Movies")
    assert_text("Table goes here")
  end

  def test_renders_breadcrumbs
    render_inline(Bali::IndexPage::Component.new(
      title: "Movies",
      breadcrumbs: [
        { name: "Dashboard", href: "/", icon_name: "home" },
        { name: "Movies" }
      ]
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector(".breadcrumbs")
    assert_text("Dashboard")
  end

  def test_renders_action_buttons
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_action { "New Movie Button" }
      page.with_body { "Content" }
    end
    assert_text("New Movie Button")
  end

  def test_renders_subtitle
    render_inline(Bali::IndexPage::Component.new(title: "Movies", subtitle: "24 total")) do |page|
      page.with_body { "Content" }
    end
    assert_text("24 total")
  end

  def test_renders_nav_between_header_and_body
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_nav { page.tag.a("Subnav link", href: "/movies/upcoming") }
      page.with_body { "Content" }
    end
    assert_selector(".page-nav.mt-4 a[href='/movies/upcoming']", text: "Subnav link")

    html = page.native.to_html
    assert_operator html.index("Movies"), :<, html.index("Subnav link")
    assert_operator html.index("Subnav link"), :<, html.index("Content")
  end

  def test_does_not_render_nav_wrapper_without_nav
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_body { "Content" }
    end
    assert_no_selector(".page-nav")
  end

  def test_renders_back_button
    render_inline(Bali::IndexPage::Component.new(
      title: "Approval Requests",
      back: { href: "/initiatives/1" }
    )) do |page|
      page.with_body { "Content" }
    end
    assert_selector("a.back-button[href='/initiatives/1']")
  end

  def test_renders_no_back_button_by_default
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_body { "Content" }
    end
    assert_no_selector(".back-button")
  end
end
