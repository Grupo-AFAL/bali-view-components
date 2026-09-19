# frozen_string_literal: true

require "test_helper"

# The Bali::PageComponents::Shared contract, walked over all FIVE page components.
#
# One test per rule and not five copies per component: copied coverage is what left ShowPage and
# DashboardPage with no test at all of v3's ⋯ menu while IndexPage had six. Adding a sixth page
# component should mean adding it to this list and nothing else.
class BaliPageComponentsSharedContractTest < ComponentTestCase
  PAGE_COMPONENTS = [
    Bali::DashboardPage::Component,
    Bali::DocumentPage::Component,
    Bali::FormPage::Component,
    Bali::IndexPage::Component,
    Bali::ShowPage::Component
  ].freeze

  # All five inherit `:full`; FormPage is the only exception, and for reading width.
  DEFAULT_MAX_WIDTHS = {
    Bali::DashboardPage::Component => :full,
    Bali::DocumentPage::Component => :full,
    Bali::FormPage::Component => :md,
    Bali::IndexPage::Component => :full,
    Bali::ShowPage::Component => :full
  }.freeze

  def test_the_five_render_the_shared_header_surface
    each_page do |component|
      render_inline(component.new(
        title: "The Matrix",
        subtitle: "1999",
        breadcrumbs: [ { name: "Movies", href: "/movies" }, { name: "The Matrix" } ],
        back: { href: "/movies" }
      )) do |page|
        page.with_title_tag { "Sci-Fi" }
        page.with_nav { "Subnav" }
        page.with_action { "Edit" }
        page.with_body { "Body content" }
      end

      assert_page component, ".breadcrumbs", "no pinta los breadcrumbs"
      assert_page component, "a.back-button[href='/movies']", "no pinta el botón de volver"
      assert_page component, ".page-header-component .title", "no pinta el título"
      assert_page component, ".page-header-component .subtitle", "no pinta el subtítulo"
      assert_page component, ".page-nav", "no pinta el slot nav"
      assert_text_in component, "The Matrix"
      assert_text_in component, "1999"
      assert_text_in component, "Sci-Fi"
      assert_text_in component, "Edit"
      assert_text_in component, "Body content"
    end
  end

  # The order is part of the contract: the nav is second-level navigation and goes BETWEEN the
  # header and the body, not underneath everything.
  #
  # #685: with no subtitle all five emitted `<h6 class="subtitle"></h6>`. An empty heading is an
  # unnamed section in the document outline and an axe violation, and none of the five pages had an
  # h1: the hierarchy started at h3.
  def test_the_five_emit_no_empty_headings
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) { |page| page.with_body { "Body" } }

      assert_empty empty_headings,
                   "#{component}: emite headings vacíos (#{empty_headings.map(&:tag_name).join(', ')})"
    end
  end

  def test_the_five_emit_no_empty_headings_with_every_slot_filled
    each_page do |component|
      render_inline(component.new(
        title: "The Matrix", subtitle: "1999", back: { href: "/movies" }
      )) do |page|
        page.with_title_tag { "Sci-Fi" }
        page.with_nav { "Subnav" }
        page.with_action { "Edit" }
        page.with_body { "Body" }
        page.with_sidebar { "Sidebar" }
      end

      assert_empty empty_headings, "#{component}: emite headings vacíos con todos los slots"
    end
  end

  def test_the_five_name_the_page_with_exactly_one_h1
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) { |page| page.with_body { "Body" } }

      assert_equal 1, page.all("h1", visible: :all).size,
                   "#{component}: no pinta exactamente un h1"
      assert_equal "The Matrix", page.find("h1", visible: :all).text.strip,
                   "#{component}: el h1 no es el título de la página"
    end
  end

  # Inside the h1 the tags became part of its accessible name and the heading announced itself as
  # "The Matrix Sci-Fi".
  def test_the_five_keep_title_tags_out_of_the_heading
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) do |page|
        page.with_title_tag { "Sci-Fi" }
        page.with_body { "Body" }
      end

      assert_equal "The Matrix", page.find("h1", visible: :all).text.strip,
                   "#{component}: los title_tags entraron al nombre accesible del h1"
      assert page.has_css?(".page-header-title > h1.title"),
             "#{component}: el h1 no es hijo directo de la fila de título"
      assert_text_in component, "Sci-Fi"
    end
  end

  # The back button is an icon-only link: with no accessible name it is an anonymous node.
  def test_the_five_name_the_back_button
    each_page do |component|
      render_inline(component.new(title: "The Matrix", back: { href: "/movies" })) do |page|
        page.with_body { "Body" }
      end

      assert page.has_css?(".back-button[aria-label='#{I18n.t('bali_view.page_header.back')}']"),
             "#{component}: el botón de volver no tiene nombre accesible"
    end
  end

  def test_the_five_place_the_nav_between_the_header_and_the_body
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) do |page|
        page.with_nav { "Subnav" }
        page.with_body { "Body content" }
      end

      html = page.native.to_html
      assert html.index("The Matrix") < html.index("Subnav"),
             "#{component}: el nav se pinta antes del título"
      assert html.index("Subnav") < html.index("Body content"),
             "#{component}: el nav se pinta después del cuerpo"
    end
  end

  def test_the_five_omit_the_nav_wrapper_when_there_is_no_nav
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) { |page| page.with_body { "Body" } }

      refute page.has_css?(".page-nav"),
             "#{component}: pinta el contenedor del nav sin slot nav"
    end
  end

  # The reason `max_width:` lives in the concern: the same symbol has to give the same class in all
  # five. `:lg` used to be `max-w-5xl` in the two that accepted it and an ArgumentError in the other
  # three, and `:md` did not exist in DashboardPage.
  def test_the_five_resolve_max_width_through_the_same_table
    Bali::PageComponents::Shared::MAX_WIDTHS.each do |key, css_class|
      each_page do |component|
        render_inline(component.new(title: "The Matrix", max_width: key)) do |page|
          page.with_body { "Body" }
        end

        assert page.has_css?("#{root_selector(component)}.mx-auto.#{css_class.tr(':', '\\:')}"),
               "#{component}: max_width: #{key.inspect} no resolvió a #{css_class}"
      end
    end
  end

  def test_the_five_reject_an_unknown_max_width
    each_page do |component|
      error = assert_raises(ArgumentError) { component.new(title: "The Matrix", max_width: :huge) }

      assert_match(/Unknown max_width/, error.message, "#{component}: mensaje inesperado")
    end
  end

  # The defaults do diverge —and should: the three that never had a container inherit `full`, which
  # is a no-op, so the unification does not move their layout.
  def test_each_page_component_keeps_its_documented_default_width
    each_page do |component|
      assert_equal DEFAULT_MAX_WIDTHS.fetch(component), component.default_max_width,
                   "#{component}: cambió el ancho por defecto"
    end
  end

  # v3's ⋯. ShowPage, DashboardPage and FormPage inherited it from the concern with no test looking
  # at it.
  def test_the_five_move_secondary_actions_into_the_overflow_menu
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) do |page|
        page.with_action { "Edit" }
        page.with_secondary_action(name: "Import", href: "/movies/import", icon: "upload")
        page.with_body { "Body" }
      end

      assert page.has_css?('.dropdown [role="menuitem"][href="/movies/import"]', visible: :all),
             "#{component}: la acción secundaria no cayó en el menú ⋯"
      assert page.has_css?('[aria-label="More actions"]', count: 1, visible: :all),
             "#{component}: no pinta exactamente un disparador del menú ⋯"
    end
  end

  def test_the_five_omit_the_overflow_menu_without_secondary_actions
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) do |page|
        page.with_action { "Edit" }
        page.with_body { "Body" }
      end

      refute page.has_css?('[aria-label="More actions"]', visible: :all),
             "#{component}: pinta un menú ⋯ vacío"
    end
  end

  def test_the_five_offer_the_export_menu
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) do |page|
        page.with_export(url: "/movies")
        page.with_body { "Body" }
      end

      assert page.has_css?("span.menu-title", text: "Export filtered", visible: :all),
             "#{component}: el menú de exportar no lleva encabezado"
      assert page.has_css?('a[href="/movies?format=csv"][data-turbo="false"]', visible: :all),
             "#{component}: falta el enlace de CSV"
    end
  end

  # The grid ShowPage and FormPage had copied verbatim, now in the concern and available to all
  # five.
  def test_the_five_share_one_body_and_sidebar_grid
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) do |page|
        page.with_body { "Body content" }
        page.with_sidebar { "Sidebar content" }
      end

      assert page.has_css?(".grid.grid-cols-1.lg\\:grid-cols-3 .lg\\:col-span-2",
                           text: "Body content"),
             "#{component}: el cuerpo no ocupa las dos terceras partes del grid"
      assert_text_in component, "Sidebar content"
    end
  end

  def test_sidebar_width_narrows_the_sidebar_in_the_five
    each_page do |component|
      render_inline(component.new(title: "The Matrix", sidebar_width: :narrow)) do |page|
        page.with_body { "Body content" }
        page.with_sidebar { "Sidebar content" }
      end

      assert page.has_css?(".grid.lg\\:grid-cols-4 .lg\\:col-span-3", text: "Body content"),
             "#{component}: sidebar_width: :narrow no cambió el grid"
    end
  end

  def test_the_five_reject_an_unknown_sidebar_width
    each_page do |component|
      error = assert_raises(ArgumentError) do
        component.new(title: "The Matrix", sidebar_width: :enormous)
      end

      assert_match(/Unknown sidebar_width/, error.message, "#{component}: mensaje inesperado")
    end
  end

  def test_the_five_drop_the_sidebar_grid_when_there_is_no_sidebar
    each_page do |component|
      render_inline(component.new(title: "The Matrix")) { |page| page.with_body { "Body" } }

      refute page.has_css?(".lg\\:col-span-2"),
             "#{component}: pinta la mitad del grid sin barra lateral"
    end
  end

  private

  def each_page(&block)
    PAGE_COMPONENTS.each(&block)
  end

  def root_selector(component)
    ".#{component.module_parent.name.demodulize.underscore.dasherize}-component"
  end

  def assert_page(component, selector, message)
    assert page.has_css?(selector, visible: :all), "#{component}: #{message}"
  end

  def assert_text_in(component, text)
    assert_includes page.native.to_html, text, "#{component}: falta el texto #{text.inspect}"
  end

  def empty_headings
    page.all("h1,h2,h3,h4,h5,h6", visible: :all).reject { |h| h.text(:all).strip.present? }
  end
end
