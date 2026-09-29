# frozen_string_literal: true

require "test_helper"

# The export never had tests of its own, which is why it survived so long exporting EVERYTHING from
# a filtered listing.
class BaliDataTableExportComponentTest < ComponentTestCase
  def test_the_href_carries_the_active_slice
    render_inline(export(params: { "q" => { "name_cont" => "dune" }, "group_by" => "status" }))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    assert_includes href, "q%5Bname_cont%5D=dune"
    assert_includes href, "group_by=status"
    assert_includes href, "format=csv"
  end

  def test_the_href_does_not_carry_the_page
    # Exporting ONLY page 3 is worse than exporting too much: the user asked for "the listing".
    render_inline(export(params: { "page" => "3", "group_by" => "status" }))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    refute_includes href, "page="
    assert_includes href, "group_by=status"
  end

  def test_the_href_does_not_carry_the_one_shot_orders
    # THE test that justifies using ToolbarHref instead of `request.fullpath`: on the server
    # `clear_filters` runs `Rails.cache.delete(cache_key)`, so a user standing on
    # `?clear_filters=true` wiped their stored filters by clicking export.
    render_inline(export(params: { "clear_filters" => "true", "clear_search" => "true" }))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    refute_includes href, "clear_filters"
    refute_includes href, "clear_search"
  end

  def test_a_url_that_already_carries_a_query_string_is_not_corrupted
    # A bare `?` gave `/movies?scope=archived?format=csv`, which Rack reads as ONE corrupt scope and
    # no format.
    render_inline(export(url: "/movies?scope=archived"))

    href = page.find("a", text: "CSV", visible: :all)["href"]
    assert_includes href, "scope=archived"
    assert_includes href, "format=csv"
    assert_equal 1, href.count("?")
  end

  def test_explicit_empty_params_is_the_opt_out
    render_inline(export(params: {}))

    assert_equal "/movies?format=csv", page.find("a", text: "CSV", visible: :all)["href"]
  end

  def test_no_request_context_does_not_blow_up
    # `params: nil` falls to `request_query_params`, which outside a request returns {}.
    render_inline(export(params: nil))

    assert_equal "/movies?format=csv", page.find("a", text: "CSV", visible: :all)["href"]
  end

  def test_every_link_opts_out_of_turbo_drive
    # A CSV/XLSX is not a response Turbo Drive can render: the visit stalls halfway instead of
    # firing the download.
    render_inline(export)

    assert_selector('a[data-turbo="false"]', count: 3, visible: :all)
  end

  def test_no_dead_rails_ujs_method_attribute
    render_inline(export)

    assert_no_selector("a[data-method]", visible: :all)
  end

  def test_the_method_keyword_is_gone
    error = assert_raises(ArgumentError) do
      Bali::DataTable::Export::Component.new(url: "/movies", method: :post)
    end
    assert_includes error.message, "method"
  end

  def test_explicit_params_switch_the_client_side_re_sync_off
    # `params: {}` is the opt-out ("export everything, deliberately") and the controller undid it the
    # moment it booted, rewriting the href from `window.location`.
    render_inline(export(params: {}))
    assert_selector('[data-export-links-sync-value="false"]', visible: :all)

    render_inline(export(params: nil))
    assert_selector('[data-export-links-sync-value="true"]', visible: :all)
  end

  # Both halves of the SAME link: the server paints the href and the controller re-syncs it from the
  # URL. With the lists apart, moving a param on one side left the other dragging along what the
  # first had just dropped, and nothing failed.
  def test_the_transient_params_list_is_the_same_in_ruby_and_in_javascript
    source = Bali::Engine.root.join("app/components/bali/data_table/export_links_controller.js").read
    literal = source[/const TRANSIENT_PARAMS = \[(.*?)\]/m, 1]
    refute_nil literal, "no se encontró el literal TRANSIENT_PARAMS en el controlador"

    assert_equal Bali::DataTable::ToolbarHref::TRANSIENT_PARAMS, literal.scan(/'([^']+)'/).flatten
  end

  private

  def export(url: "/movies", params: {}, formats: %i[csv excel pdf])
    Bali::DataTable::Export::Component.new(url: url, params: params, formats: formats)
  end
end
