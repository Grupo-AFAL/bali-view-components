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
end
