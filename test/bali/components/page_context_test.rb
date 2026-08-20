# frozen_string_literal: true

require "test_helper"

# `context:` is declared once in Bali::PageComponents::Shared, so it is tested once here for
# the two components the migration is about: FormPage, which also resolves its Card from it,
# and ShowPage, which shares the chrome and nothing else.
class BaliPageContextTest < ComponentTestCase
  DRAWER_URL = "/admin/studios/new?layout=false"
  PAGE_URL = "/admin/studios/new"

  BREADCRUMBS = [ { name: "Studios", href: "/admin/studios" }, { name: "New" } ].freeze

  # --- autodetection -------------------------------------------------------------------

  def test_autodetects_a_page_when_the_request_is_not_a_drawer_one
    with_request_url PAGE_URL do
      render_form_page(back: { href: "/admin/studios" }, breadcrumbs: BREADCRUMBS)
    end

    assert_selector(".card")
    assert_selector(".breadcrumbs")
    assert_selector("a[href='/admin/studios'].back-button")
  end

  def test_autodetects_a_drawer_from_the_hosts_drawer_request_helper
    with_request_url DRAWER_URL do
      render_form_page(back: { href: "/admin/studios" }, breadcrumbs: BREADCRUMBS)
    end

    assert_text("New Studio")
    assert_no_selector(".card")
    assert_no_selector(".breadcrumbs")
    assert_no_selector(".back-button")
  end

  # A host that declares no `drawer_request?` at all -- and a Lookbook preview, and this very
  # test suite outside `with_request_url` -- has to keep rendering pages. This is the whole
  # reason the lookup is guarded by `respond_to?` instead of assuming the concern is included.
  def test_a_view_context_without_the_helper_renders_a_page
    view_context = ActionController::Base.new.tap { |c| c.request = vc_test_request }.view_context
    refute_respond_to(view_context, :drawer_request?)

    component = Bali::FormPage::Component.new(title: "New Studio")
    html = component.render_in(view_context) { |page| page.with_body { "Form" } }

    assert_includes(html, "card")
    assert_includes(html, "Form")
  end

  # --- forcing beats autodetection -----------------------------------------------------

  def test_context_page_wins_over_a_drawer_request
    with_request_url DRAWER_URL do
      render_form_page(context: :page, back: { href: "/admin/studios" }, breadcrumbs: BREADCRUMBS)
    end

    assert_selector(".card")
    assert_selector(".breadcrumbs")
    assert_selector("a[href='/admin/studios'].back-button")
  end

  def test_context_drawer_wins_over_a_page_request
    with_request_url PAGE_URL do
      render_form_page(context: :drawer, back: { href: "/admin/studios" },
                       breadcrumbs: BREADCRUMBS)
    end

    assert_no_selector(".card")
    assert_no_selector(".breadcrumbs")
    assert_no_selector(".back-button")
  end

  def test_an_unknown_context_raises
    error = assert_raises(ArgumentError) do
      Bali::FormPage::Component.new(title: "New Studio", context: :modal)
    end

    assert_match(/Unknown context: :modal/, error.message)
    assert_match(/auto, page, drawer/, error.message)
  end

  # --- escape hatches ------------------------------------------------------------------

  # `card: true` is the one the issue calls out: a Card is decoration, and wanting it inside a
  # drawer is a legitimate taste, so an explicit value beats the context.
  def test_card_true_survives_context_drawer
    render_form_page(context: :drawer, card: true)

    assert_selector(".card")
  end

  def test_card_false_survives_context_page
    render_form_page(context: :page, card: false)

    assert_no_selector(".card")
  end

  # `back:` and the breadcrumbs go the other way round: they are suppressed even when passed,
  # because the canonical migrated call site DOES pass `back:` and expects it gone inside the
  # drawer. `context: :page` is their escape hatch, and it restores them inside a drawer
  # request -- which is the only combination that would otherwise be unreachable.
  def test_back_survives_a_drawer_request_when_the_context_is_forced_to_page
    with_request_url DRAWER_URL do
      render_form_page(context: :page, back: { href: "/admin/studios" }, breadcrumbs: BREADCRUMBS)
    end

    assert_selector("a[href='/admin/studios'].back-button")
    assert_selector(".breadcrumbs")
  end

  def test_a_drawer_can_keep_the_card_and_drop_the_chrome_at_once
    render_form_page(context: :drawer, card: true, back: { href: "/admin/studios" },
                     breadcrumbs: BREADCRUMBS)

    assert_selector(".card")
    assert_no_selector(".back-button")
    assert_no_selector(".breadcrumbs")
  end

  # --- what the context does NOT take away ---------------------------------------------

  def test_a_drawer_keeps_the_title_the_actions_and_the_body
    render_form_page(context: :drawer, subtitle: "Fill it in") do |page|
      page.with_action { "Save draft" }
      page.with_title_tag { "Draft" }
    end

    assert_text("New Studio")
    assert_text("Fill it in")
    assert_text("Save draft")
    assert_text("Draft")
    assert_text("Form")
  end

  # --- heading level (#1055) -------------------------------------------------------------

  # The heading is the fourth contextual axis, after `back:`, the breadcrumbs and the Card:
  # inside a drawer the page underneath already holds the document's `h1`, so the panel's
  # title steps down to `h2` instead of duplicating it.

  def test_a_drawer_lowers_the_heading_to_h2
    render_form_page(context: :drawer)

    assert_selector("h2.title", text: "New Studio")
    assert_no_selector("h1")
  end

  def test_a_page_keeps_the_h1
    render_form_page(context: :page)

    assert_selector("h1.title", text: "New Studio")
  end

  def test_a_drawer_request_lowers_the_heading_when_autodetecting
    with_request_url DRAWER_URL do
      render_form_page
    end

    assert_selector("h2.title", text: "New Studio")
  end

  # Same contract as `card:`: `nil` hands the decision to the context, an explicit value
  # wins in BOTH directions.
  def test_an_explicit_heading_survives_the_drawer_context
    render_form_page(context: :drawer, heading: :h1)

    assert_selector("h1.title", text: "New Studio")
  end

  def test_an_explicit_heading_survives_the_page_context
    render_form_page(context: :page, heading: :h3)

    assert_selector("h3.title", text: "New Studio")
  end

  def test_an_unknown_heading_raises
    error = assert_raises(ArgumentError) do
      Bali::FormPage::Component.new(title: "New Studio", heading: :div)
    end

    assert_match(/Unknown heading: :div/, error.message)
    assert_match(/h1, h2, h3, h4, h5, h6/, error.message)
  end

  def test_show_page_lowers_its_heading_in_a_drawer
    render_inline(Bali::ShowPage::Component.new(title: "Studio", context: :drawer)) do |page|
      page.with_body { "Details" }
    end

    assert_selector("h2.title", text: "Studio")
    assert_no_selector("h1")
  end

  # --- the predicate the host reads ------------------------------------------------------

  def test_drawer_predicate_is_yielded_to_the_block
    seen = nil
    with_request_url DRAWER_URL do
      render_inline(Bali::FormPage::Component.new(title: "New Studio")) do |page|
        seen = page.drawer?
        page.with_body { "Form" }
      end
    end

    assert(seen, "expected the component to report itself as a drawer")
  end

  def test_drawer_predicate_is_false_on_a_page
    seen = nil
    with_request_url PAGE_URL do
      render_inline(Bali::FormPage::Component.new(title: "New Studio")) do |page|
        seen = page.drawer?
        page.with_body { "Form" }
      end
    end

    refute(seen)
  end

  # --- ShowPage shares all of it ---------------------------------------------------------

  def test_show_page_drops_its_chrome_in_a_drawer
    render_inline(Bali::ShowPage::Component.new(
      title: "Studio", context: :drawer, back: { href: "/studios" }, breadcrumbs: BREADCRUMBS
    )) { |page| page.with_body { "Details" } }

    assert_text("Studio")
    assert_text("Details")
    assert_no_selector(".back-button")
    assert_no_selector(".breadcrumbs")
  end

  def test_show_page_autodetects_a_drawer_request
    with_request_url DRAWER_URL do
      render_inline(Bali::ShowPage::Component.new(
        title: "Studio", back: { href: "/studios" }
      )) { |page| page.with_body { "Details" } }
    end

    assert_no_selector(".back-button")
  end

  def test_show_page_keeps_its_chrome_on_a_page
    with_request_url PAGE_URL do
      render_inline(Bali::ShowPage::Component.new(
        title: "Studio", back: { href: "/studios" }, breadcrumbs: BREADCRUMBS
      )) { |page| page.with_body { "Details" } }
    end

    assert_selector("a[href='/studios'].back-button")
    assert_selector(".breadcrumbs")
  end

  private

  def render_form_page(**options)
    render_inline(Bali::FormPage::Component.new(title: "New Studio", **options)) do |page|
      yield page if block_given?
      page.with_body { "Form" }
    end
  end
end
