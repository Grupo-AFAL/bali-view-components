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

  def test_secondary_actions_live_in_the_overflow_menu_and_not_in_the_row
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_action { "New Movie Button" }
      page.with_secondary_action(name: "Import", href: "/movies/import", icon_name: "upload")
      page.with_body { "Content" }
    end

    assert_selector('.dropdown [role="menuitem"][href="/movies/import"]', text: "Import",
                    visible: :all)
    assert_selector('[aria-label="More actions"]', count: 1, visible: :all)
  end

  def test_no_overflow_menu_without_secondary_actions
    # Mismo criterio que el ⋯ de la toolbar: un botón que abre un menú vacío es un bug.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_action { "New Movie Button" }
      page.with_body { "Content" }
    end

    assert_no_selector('[aria-label="More actions"]', visible: :all)
  end

  def test_export_renders_a_titled_section_with_one_item_per_format
    # El título es el que NOMBRA la acción: con un item por formato y sin él el menú diría
    # "CSV / Excel / PDF" y nadie sabría de qué.
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
    # El ⋯ vive en el PageHeader, FUERA del nodo que el turbo_stream del listado reemplaza:
    # sin el controlador el primer filtro deja los href congelados.
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies")
      page.with_body { "Content" }
    end

    assert_selector('[data-controller~="export-links"]', count: 1, visible: :all)
    assert_selector('[data-export-links-target="link"]', count: 3, visible: :all)
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
