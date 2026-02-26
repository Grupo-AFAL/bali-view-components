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
end
