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

  # Every stat renders as a real StatCard, and this template used to hand it the keyword
  # StatCard itself deprecates — so a host got one warning per stat card for a call it
  # never wrote and could not change. Twelve of the twenty-seven warnings the dummy fired
  # came from here (#797). Same leak the deprecator test pins for PageHeader and Level.
  #
  # The icon is asserted alongside the silence because the cheap way to quiet this warning
  # is to drop the keyword, which drops the icon too and still passes a test that only
  # counts warnings.
  def test_stats_do_not_leak_the_stat_card_deprecation_to_the_host
    warning = capture_deprecation do
      render_inline(Bali::DashboardPage::Component.new(title: "Dashboard")) do |page|
        page.with_stat(label: "Total Movies", value: "1,234", icon: "film")
        page.with_body { "Content" }
      end
    end

    assert_nil(warning)
    assert_selector(".rounded-full svg")
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
