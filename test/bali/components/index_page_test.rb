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
    assert_selector('a[href="/movies?format=csv"][data-turbo="false"]', text: "CSV", visible: :all)
    assert_selector('a[href="/movies?format=excel"]', text: "Excel", visible: :all)
    assert_selector('a[href="/movies?format=pdf"]', text: "PDF", visible: :all)
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

  # On the server `clear_filters` runs `Rails.cache.delete(cache_key)`: a user standing on
  # `?clear_filters=true` wiped their stored filters by clicking export.
  def test_export_links_drop_the_one_shot_orders
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies", params: { "q" => { "name_cont" => "dune" },
                                                 "clear_filters" => "true", "clear_search" => "true" })
      page.with_body { "Content" }
    end

    assert_selector('a[href="/movies?format=csv&q%5Bname_cont%5D=dune"]', visible: :all)
  end

  # A bare `?` gave `/movies?scope=archived?format=csv`, which Rack reads as ONE corrupt scope and
  # no format.
  def test_export_links_keep_the_query_string_of_the_url
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies?scope=archived", params: {})
      page.with_body { "Content" }
    end

    assert_selector('a[href="/movies?format=csv&scope=archived"]', visible: :all)
  end

  def test_export_offers_the_formats_in_the_order_given
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies", formats: %i[pdf csv])
      page.with_body { "Content" }
    end

    links = page.all('[data-export-links-target="link"]', visible: :all)
    assert_equal %w[/movies?format=pdf /movies?format=csv], links.pluck("href")
  end

  def test_export_takes_formats_given_as_strings
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies", formats: %w[excel])
      page.with_body { "Content" }
    end

    assert_selector('a[href="/movies?format=excel"]', text: "Excel", visible: :all)
  end

  # Raised and not skipped: a misspelt format used to drop out of the ⋯ without a word.
  def test_export_raises_on_an_unknown_format
    error = assert_raises(ArgumentError) do
      Bali::IndexPage::Component.new(title: "Movies").with_export(url: "/movies", formats: %w[csv xml])
    end

    assert_equal 'Invalid export formats: ["csv", "xml"]. Valid: one or more of csv, excel, pdf, json',
                 error.message
  end

  # Raised and not skipped: an export left with no format vanishes without a word, or leaves its
  # title alone in a ⋯ shared with other actions.
  def test_export_raises_without_a_format
    [ [], nil, [ nil ] ].each do |formats|
      assert_raises(ArgumentError, "formats: #{formats.inspect}") do
        Bali::IndexPage::Component.new(title: "Movies").with_export(url: "/movies", formats: formats)
      end
    end
  end

  # The label key is interpolated, so `i18n_usage_test` only checks its prefix.
  def test_every_export_format_has_a_label_in_both_locales
    %i[en es].each do |locale|
      labels = I18n.t("bali_view.page_components.export.formats", locale: locale).compact_blank

      assert_equal Bali::PageComponents::Shared::EXPORT_FORMATS.sort, labels.keys.sort, locale
    end
  end

  def test_export_links_read_the_slice_from_the_request_by_default
    with_request_url "/admin/movies?q%5Bname_cont%5D=dune&page=2" do
      render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
        page.with_export(url: "/admin/movies")
        page.with_body { "Content" }
      end
    end

    assert_selector('a[href="/admin/movies?format=csv&q%5Bname_cont%5D=dune"]', visible: :all)
  end

  # `{}` is the opt-out, "export everything, deliberately": it has to beat the query string of the
  # request, which is the only place `nil` and `{}` give different links.
  def test_export_links_with_empty_params_ignore_the_request
    with_request_url "/admin/movies?q%5Bname_cont%5D=dune" do
      render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
        page.with_export(url: "/admin/movies", params: {})
        page.with_body { "Content" }
      end
    end

    assert_selector('a[href="/admin/movies?format=csv"]', visible: :all)
  end

  # Bali::Dropdown items default to `method: :get`, which Link paints as Rails-UJS's
  # `data-method="get"`: dead under Turbo.
  def test_export_links_carry_no_rails_ujs_method
    render_inline(Bali::IndexPage::Component.new(title: "Movies")) do |page|
      page.with_export(url: "/movies")
      page.with_body { "Content" }
    end

    assert_selector('[data-export-links-target="link"]', count: 3, visible: :all)
    assert_no_selector('[data-export-links-target="link"][data-method]', visible: :all)
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
