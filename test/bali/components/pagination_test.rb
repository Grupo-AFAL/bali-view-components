# frozen_string_literal: true

require "test_helper"

class BaliPaginationComponentTest < ComponentTestCase
  def setup
    # Pagy 43.x uses Pagy::Offset class with `limit` instead of `items`
    @pagy = Pagy::Offset.new(count: 100, page: 3, limit: 10)
  end

  def test_renders_pagination_with_multiple_pages
    render_inline(Bali::Pagination::Component.new(pagy: @pagy))
    assert_selector("nav.pagy-nav-daisyui")
    assert_selector(".join")
    assert_selector(".join-item.btn", minimum: 5)
  end

  def test_renders_previous_and_next_buttons
    render_inline(Bali::Pagination::Component.new(pagy: @pagy))
    assert_selector("a.join-item", text: "«")
    assert_selector("a.join-item", text: "»")
  end

  # `btn-active` a secas pasaba este test mientras la página actual se veía IGUAL que las
  # demás: en daisyUI 5 apenas oscurece un `btn` plano. El marcador tiene que ser el mismo
  # que usa el resto de Bali para "esto es lo seleccionado" (`ViewSwitch::View`).
  def test_marks_current_page_as_active
    render_inline(Bali::Pagination::Component.new(pagy: @pagy))
    assert_selector("button.btn-active.btn-primary[aria-current='page']", text: "3")
    assert_no_selector("a.btn-primary")
  end

  def test_does_not_render_when_only_one_page
    single_page = Pagy::Offset.new(count: 5, page: 1, limit: 10)
    render_inline(Bali::Pagination::Component.new(pagy: single_page))
    assert_no_selector("nav")
  end

  def test_disables_previous_button_on_first_page
    first_page = Pagy::Offset.new(count: 100, page: 1, limit: 10)
    render_inline(Bali::Pagination::Component.new(pagy: first_page))
    assert_selector("button.btn-disabled[disabled]", text: "«")
  end

  def test_disables_next_button_on_last_page
    last_page = Pagy::Offset.new(count: 100, page: 10, limit: 10)
    render_inline(Bali::Pagination::Component.new(pagy: last_page))
    assert_selector("button.btn-disabled[disabled]", text: "»")
  end

  def test_applies_size_classes
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, size: :sm))
    assert_selector(".btn-sm")
  end

  def test_applies_variant_classes
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, variant: :outline))
    assert_selector(".btn-outline")
  end

  def test_links_to_the_given_url
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, url: "/movies?q=batman"))
    assert_selector("a.join-item[href='/movies?q=batman&page=4']", text: "4")
  end

  # #654: sin ancla, paginar una sección a media página brinca al tope.
  def test_appends_the_fragment_to_every_link
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, url: "/movies", fragment: "#results"))
    assert_selector("a.join-item[href='/movies?page=4#results']", text: "4")
    assert_selector("a.join-item[href='/movies?page=2#results']", text: "«")
  end

  # #654: sin esto no se puede paginar dentro de un Turbo Frame.
  def test_passes_data_attributes_to_every_link
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, data: { turbo_frame: "movies" }))
    assert_selector("a.join-item[data-turbo-frame='movies']", minimum: 3)
  end
end
