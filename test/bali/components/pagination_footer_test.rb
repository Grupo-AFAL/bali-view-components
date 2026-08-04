# frozen_string_literal: true

require "test_helper"

class BaliPaginationFooterComponentTest < ComponentTestCase
  def setup
    # Pagy 43.x uses Pagy::Offset class with `limit` instead of `items`
    @pagy = Pagy::Offset.new(count: 47, page: 1, limit: 10)
  end

  def test_renders_summary_text
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy))
    assert_text("Showing 1-10 of 47 items")
  end

  def test_renders_pagination_when_multiple_pages
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy))
    assert_selector(".join") # Pagination component uses join class
  end

  def test_hides_pagination_when_single_page
    single_page_pagy = Pagy::Offset.new(count: 5, page: 1, limit: 10)
    render_inline(Bali::PaginationFooter::Component.new(pagy: single_page_pagy))
    assert_no_selector(".join")
  end

  def test_uses_custom_item_name
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, item_name: "studios"))
    assert_text("Showing 1-10 of 47 studios")
  end

  def test_picks_the_singular_from_a_hash_item_name
    single_pagy = Pagy::Offset.new(count: 1, page: 1, limit: 10)
    render_inline(Bali::PaginationFooter::Component.new(
      pagy: single_pagy, item_name: { one: "movie", other: "movies" }
    ))
    assert_text("Showing 1-1 of 1 movie")
  end

  def test_hides_summary_when_show_summary_is_false
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, show_summary: false))
    assert_no_text("Showing")
  end

  def test_hides_pagination_when_show_pagination_is_false
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, show_pagination: false))
    assert_no_selector(".join")
  end

  def test_does_not_render_when_pagy_is_nil
    render_inline(Bali::PaginationFooter::Component.new(pagy: nil))
    assert(page.text.blank?)
  end

  def test_renders_flex_container_with_justify_between
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy))
    assert_selector(".flex.items-center.justify-between")
  end

  def test_shows_correct_page_range_on_page_2
    page_2_pagy = Pagy::Offset.new(count: 47, page: 2, limit: 10)
    render_inline(Bali::PaginationFooter::Component.new(pagy: page_2_pagy))
    assert_text("Showing 11-20 of 47 items")
  end

  def test_shows_correct_range_on_last_page
    last_page_pagy = Pagy::Offset.new(count: 47, page: 5, limit: 10)
    render_inline(Bali::PaginationFooter::Component.new(pagy: last_page_pagy))
    assert_text("Showing 41-47 of 47 items")
  end

  # Con cero resultados el footer decía "Showing 0-0 of 0 items", que no informa nada.
  def test_renders_nothing_without_results
    empty_pagy = Pagy::Offset.new(count: 0, page: 1, limit: 10)
    render_inline(Bali::PaginationFooter::Component.new(pagy: empty_pagy))
    assert(page.text.blank?)
    assert_no_selector("div")
  end

  # Un contenedor con su padding vertical y nada dentro sigue empujando el layout.
  def test_renders_nothing_when_summary_and_pagination_are_both_off
    render_inline(
      Bali::PaginationFooter::Component.new(pagy: @pagy, show_summary: false, show_pagination: false)
    )
    assert_no_selector("div")
  end

  def test_forwards_size_and_variant_to_pagination
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, size: :sm, variant: :outline))
    assert_selector(".join-item.btn-sm.btn-outline")
  end

  def test_forwards_url_and_fragment_to_pagination
    render_inline(
      Bali::PaginationFooter::Component.new(pagy: @pagy, url: "/movies", fragment: "#results")
    )
    assert_selector("a.join-item[href='/movies?page=2#results']", text: "2")
  end

  def test_forwards_data_attributes_to_pagination
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, data: { turbo_frame: "movies" }))
    assert_selector("a.join-item[data-turbo-frame='movies']", minimum: 2)
  end

  def test_accepts_extra_html_attributes_on_the_wrapper
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, class: "shadow", id: "footer"))
    assert_selector("div#footer.shadow.justify-between")
  end

  # El espaciado NO viaja por `class:` justamente por esto: `py-4` y `pt-4` sobre el mismo
  # elemento los resuelve Tailwind por orden de hoja de estilos, y contra el `padding-bottom`
  # que mete `py-4` no hay `pt-*` que valga.
  def test_standing_alone_it_pads_both_sides
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy))
    assert_selector("div.py-4.gap-2")
    assert_no_selector("div.border-t")
    assert_no_selector("div.pt-4")
  end

  def test_with_a_divider_the_space_goes_above_the_line
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy, divider: true))
    assert_selector("div.gap-4.mt-4.pt-4.border-t.border-base-200")
    assert_no_selector("div.py-4")
    assert_no_selector("div.gap-2")
  end

  def test_custom_controls_replace_the_pagination
    render_inline(Bali::PaginationFooter::Component.new(pagy: @pagy)) do |footer|
      footer.with_controls { '<nav class="my-nav"></nav>'.html_safe }
    end
    assert_selector("nav.my-nav")
    assert_no_selector(".join")
  end

  # Quien trae su propia nav decide qué hacer con una sola página.
  def test_custom_controls_render_on_a_single_page
    single_page_pagy = Pagy::Offset.new(count: 5, page: 1, limit: 10)
    render_inline(Bali::PaginationFooter::Component.new(pagy: single_page_pagy)) do |footer|
      footer.with_controls { '<nav class="my-nav"></nav>'.html_safe }
    end
    assert_selector("nav.my-nav")
  end
end
