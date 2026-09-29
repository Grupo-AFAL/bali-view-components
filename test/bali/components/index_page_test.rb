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
        { name: "Dashboard", href: "/", icon: "home" },
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

  def test_secondary_actions_live_in_the_overflow_menu_and_not_in_the_row
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_action { "New Movie Button" }
      page.with_secondary_action(name: "Import", href: "/movies/import", icon: "upload")
      page.with_body { "Content" }
    end

    assert_selector('.dropdown [role="menuitem"][href="/movies/import"]', text: "Import",
                    visible: :all)
    assert_selector('[aria-label="More actions"]', count: 1, visible: :all)
  end

  def test_no_overflow_menu_without_secondary_actions
    # Same criterion as the toolbar's ⋯: a button that opens an empty menu is a bug.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_action { "New Movie Button" }
      page.with_body { "Content" }
    end

    assert_no_selector('[aria-label="More actions"]', visible: :all)
  end

  def test_export_renders_a_titled_section_with_one_item_per_format
    # The title is what NAMES the action: with one item per format and no title the menu would read
    # "CSV / Excel / PDF" and nobody would know what of.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies")
      page.with_body { "Content" }
    end

    assert_selector("span.menu-title", text: "Export filtered", visible: :all)
    assert_selector('a[href="/movies?format=csv"][data-turbo="false"]', visible: :all)
    assert_selector('a[href="/movies?format=excel"]', visible: :all)
    assert_selector('a[href="/movies?format=pdf"]', visible: :all)
  end

  def test_export_links_carry_the_active_slice
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies", params: { "q" => { "name_cont" => "dune" }, "page" => "2" })
      page.with_body { "Content" }
    end

    href = page.find('[data-export-links-target="link"]', match: :first, visible: :all)["href"]
    assert_includes href, "q%5Bname_cont%5D=dune"
    refute_includes href, "page="
  end

  def test_export_links_are_kept_in_sync_by_their_controller
    # The ⋯ lives in the PageHeader, OUTSIDE the node the listing's turbo_stream replaces: without
    # the controller the first filter leaves the hrefs frozen.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies")
      page.with_body { "Content" }
    end

    assert_selector('[data-controller~="export-links"]', count: 1, visible: :all)
    assert_selector('[data-export-links-target="link"]', count: 3, visible: :all)
    assert_selector('[data-export-links-sync-value="true"]', count: 1, visible: :all)
  end

  def test_an_explicit_params_switches_the_client_side_re_sync_off
    # `params:` is a host DECISION —`{}` means "export everything, deliberately"— and the controller
    # undid it the moment Stimulus booted, rewriting the href from the browser's URL. The Ruby tests
    # stayed green because `render_inline` runs no JS.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies", params: {})
      page.with_body { "Content" }
    end

    assert_selector('[data-export-links-sync-value="false"]', count: 1, visible: :all)
  end

  def test_the_export_items_are_described_by_the_section_title
    # Inside a `<ul role="menu">` a screen reader walks ONLY the menuitems, so the title fell outside
    # the walk and the items announced themselves as "CSV / Excel / PDF" without ever saying they
    # export. As a description and not as a name, so it does not override the visible one.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies")
      page.with_body { "Content" }
    end

    title_id = page.find("span.menu-title", visible: :all)["id"]
    refute_nil title_id
    assert_selector("span.menu-title[role='presentation']", visible: :all)
    assert_selector("[data-export-links-target='link'][aria-describedby='#{title_id}']",
                    count: 3, visible: :all)
  end

  def test_the_primary_action_and_the_overflow_share_one_container
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_action { "New Movie Button" }
      page.with_export(url: "/movies")
      page.with_body { "Content" }
    end

    assert_selector(".flex.items-center.gap-2 .dropdown", visible: :all)
    assert_selector(".flex.items-center.gap-2", text: "New Movie Button", visible: :all)
  end

  def test_renders_no_back_button_by_default
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_body { "Content" }
    end
    assert_no_selector(".back-button")
  end
end
