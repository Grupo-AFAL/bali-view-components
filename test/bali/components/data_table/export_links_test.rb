# frozen_string_literal: true

require "test_helper"

# The export never had tests of its own, which is why it survived so long exporting EVERYTHING from
# a filtered listing.
class BaliDataTableExportLinksTest < ActiveSupport::TestCase
  def test_the_href_carries_the_active_slice
    href = csv_href(params: { "q" => { "name_cont" => "dune" }, "group_by" => "status" })

    assert_includes href, "q%5Bname_cont%5D=dune"
    assert_includes href, "group_by=status"
    assert_includes href, "format=csv"
  end

  def test_the_href_does_not_carry_the_page
    # Exporting ONLY page 3 is worse than exporting too much: the user asked for "the listing".
    href = csv_href(params: { "page" => "3", "group_by" => "status" })

    refute_includes href, "page="
    assert_includes href, "group_by=status"
  end

  def test_the_href_does_not_carry_the_one_shot_orders
    # THE test that justifies using ToolbarHref instead of `request.fullpath`: on the server
    # `clear_filters` runs `Rails.cache.delete(cache_key)`, so a user standing on
    # `?clear_filters=true` wiped their stored filters by clicking export.
    href = csv_href(params: { "clear_filters" => "true", "clear_search" => "true" })

    refute_includes href, "clear_filters"
    refute_includes href, "clear_search"
  end

  def test_a_url_that_already_carries_a_query_string_is_not_corrupted
    # A bare `?` gave `/movies?scope=archived?format=csv`, which Rack reads as ONE corrupt scope and
    # no format.
    href = csv_href(url: "/movies?scope=archived")

    assert_includes href, "scope=archived"
    assert_includes href, "format=csv"
    assert_equal 1, href.count("?")
  end

  def test_one_item_per_known_format_in_the_order_given
    items = export_links(formats: %i[pdf xml csv]).items

    assert_equal %w[PDF CSV], items.pluck(:label)
    assert_equal %w[/movies?format=pdf /movies?format=csv], items.pluck(:url)
  end

  # Both halves of the SAME link: the server paints the href and the controller re-syncs it from the
  # URL. With the lists apart, moving a param on one side left the other dragging along what the
  # first had just dropped, and nothing failed.
  def test_the_transient_params_list_is_the_same_in_ruby_and_in_javascript
    source = Bali::Engine.root.join("app/components/bali/data_table/export_links_controller.js").read
    literal = source[/const TRANSIENT_PARAMS = \[(.*?)\]/m, 1]
    refute_nil literal, "TRANSIENT_PARAMS literal not found in the controller"

    assert_equal Bali::DataTable::ToolbarHref::TRANSIENT_PARAMS, literal.scan(/'([^']+)'/).flatten
  end

  private

  def export_links(url: "/movies", params: {}, formats: %i[csv excel pdf])
    Bali::DataTable::ExportLinks.new(url: url, params: params, formats: formats)
  end

  def csv_href(**options)
    export_links(**options).items.find { |item| item[:label] == "CSV" }.fetch(:url)
  end
end
