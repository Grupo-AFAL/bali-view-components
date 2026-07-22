# frozen_string_literal: true

require "test_helper"

class BaliDashboardPageComponentTest < ComponentTestCase
  def test_renders_title
    render_inline(Bali::DashboardPage::Component.new(title: "Dashboard")) do |page|
      page.with_body { "Charts here" }
    end
    assert_text("Dashboard")
    assert_text("Charts here")
  end

  def test_renders_stat_cards
    render_inline(Bali::DashboardPage::Component.new(title: "Dashboard")) do |page|
      page.with_stat(label: "Total Movies", value: "1,234", icon: "film")
      page.with_stat(label: "Revenue", value: "$45K", icon: "dollar-sign")
      page.with_body { "Content" }
    end
    assert_text("Total Movies")
    assert_text("1,234")
    assert_text("Revenue")
    assert_text("$45K")
  end

  def test_renders_actions
    render_inline(Bali::DashboardPage::Component.new(title: "Dashboard")) do |page|
      page.with_action { "Export Button" }
      page.with_body { "Content" }
    end
    assert_text("Export Button")
  end

  def test_renders_subtitle
    render_inline(Bali::DashboardPage::Component.new(
      title: "Dashboard",
      subtitle: "Welcome back"
    )) do |page|
      page.with_body { "Content" }
    end
    assert_text("Welcome back")
  end

  def test_renders_nav_between_header_and_stats
    render_inline(Bali::DashboardPage::Component.new(title: "Dashboard")) do |page|
      page.with_nav { page.tag.a("Subnav link", href: "/dashboard/sales") }
      page.with_stat(label: "Total Movies", value: "1,234")
      page.with_body { "Charts here" }
    end
    assert_selector(".page-nav.mt-4 a[href='/dashboard/sales']", text: "Subnav link")

    html = page.native.to_html
    assert_operator html.index("Dashboard"), :<, html.index("Subnav link")
    assert_operator html.index("Subnav link"), :<, html.index("Total Movies")
    assert_operator html.index("Total Movies"), :<, html.index("Charts here")
  end

  def test_does_not_render_nav_wrapper_without_nav
    render_inline(Bali::DashboardPage::Component.new(title: "Dashboard")) do |page|
      page.with_body { "Content" }
    end
    assert_no_selector(".page-nav")
  end
end
