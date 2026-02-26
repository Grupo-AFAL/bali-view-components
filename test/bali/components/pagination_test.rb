# frozen_string_literal: true

require "test_helper"

class BaliPaginationComponentTest < ComponentTestCase
  def setup
    # Pagy 43.x uses Pagy::Offset class with `limit` instead of `items`
    @pagy = Pagy::Offset.new(count: 100, page: 3, limit: 10)
    # Provide a URL for tests since there's no request context
    @test_url = "/test"
  end

  def test_renders_pagination_with_multiple_pages
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, url: @test_url))
    assert_selector("nav.pagy-nav-daisyui")
    assert_selector(".join")
    assert_selector(".join-item.btn", minimum: 5)
  end

  def test_renders_previous_and_next_buttons
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, url: @test_url))
    assert_selector("a.join-item", text: "«")
    assert_selector("a.join-item", text: "»")
  end

  def test_marks_current_page_as_active
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, url: @test_url))
    assert_selector("button.btn-active", text: "3")
  end

  def test_does_not_render_when_only_one_page
    single_page = Pagy::Offset.new(count: 5, page: 1, limit: 10)
    render_inline(Bali::Pagination::Component.new(pagy: single_page, url: @test_url))
    assert_no_selector("nav")
  end

  def test_disables_previous_button_on_first_page
    first_page = Pagy::Offset.new(count: 100, page: 1, limit: 10)
    render_inline(Bali::Pagination::Component.new(pagy: first_page, url: @test_url))
    assert_selector("button.btn-disabled[disabled]", text: "«")
  end

  def test_disables_next_button_on_last_page
    last_page = Pagy::Offset.new(count: 100, page: 10, limit: 10)
    render_inline(Bali::Pagination::Component.new(pagy: last_page, url: @test_url))
    assert_selector("button.btn-disabled[disabled]", text: "»")
  end

  def test_applies_size_classes
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, size: :sm, url: @test_url))
    assert_selector(".btn-sm")
  end

  def test_applies_variant_classes
    render_inline(Bali::Pagination::Component.new(pagy: @pagy, variant: :outline, url: @test_url))
    assert_selector(".btn-outline")
  end
end
