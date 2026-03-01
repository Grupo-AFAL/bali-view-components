# frozen_string_literal: true

require "test_helper"

class BaliFormPageComponentTest < ComponentTestCase
  def test_renders_title
    render_inline(Bali::FormPage::Component.new(title: "New Movie")) do |page|
      page.with_body { "Form here" }
    end
    assert_text("New Movie")
    assert_text("Form here")
  end

  def test_renders_breadcrumbs
    render_inline(Bali::FormPage::Component.new(
      title: "New Movie",
      breadcrumbs: [ { name: "Movies", href: "/movies" }, { name: "New" } ]
    )) do |page|
      page.with_body { "Form" }
    end
    assert_selector(".breadcrumbs")
  end

  def test_wraps_body_in_card
    render_inline(Bali::FormPage::Component.new(title: "New Movie")) do |page|
      page.with_body { "Form content" }
    end
    assert_selector(".card")
    assert_text("Form content")
  end

  def test_renders_back_button
    render_inline(Bali::FormPage::Component.new(
      title: "Edit Movie",
      back: { href: "/movies/1" }
    )) do |page|
      page.with_body { "Form" }
    end
    assert_selector("a[href='/movies/1']")
  end
end
