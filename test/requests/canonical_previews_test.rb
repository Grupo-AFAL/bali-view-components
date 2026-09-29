# frozen_string_literal: true

require "test_helper"

# The canonical preview is this release's deliverable ("copy this composition"), but it lives
# outside everything else's reach: the component tests skip it (they render classes, not previews)
# and Cypress only visits `/bali/data_table/*`. Without this, IndexPage's own glue —the include of
# `Bali::DataTable::Preview::CanonicalIndex`, the cross-directory `render partial:`, the two files in
# `do_not_eager_load`— can 500 outright and the suite stays green.
class CanonicalPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "/lookbook/preview/bali/index_page/complete" => ".index-page-component",
    "/lookbook/preview/bali/data_table/complete" => ".data-table-component",
    "/lookbook/preview/bali/table/selectable" => "[data-bulk-actions-target='selectAll']",
    "/lookbook/preview/bali/bulk_actions/toolbar" => ".bulk-actions-component"
  }.freeze

  def setup
    Tenant.create!(name: "Test Studio").movies.create!(name: "Test Movie", status: 0)
  end

  def test_the_canonical_previews_render_with_their_marker_element
    PREVIEWS.each do |path, marker|
      get path
      assert_response :ok, "#{path} no renderizó"
      assert_select marker, { minimum: 1 }, "#{path} renderizó sin #{marker}"
    end
  end

  def test_the_data_table_preview_round_trips_the_view_param
    %w[grid calendar].each do |view|
      get "/lookbook/preview/bali/data_table/complete", params: { view: view }
      assert_response :ok, "?view=#{view} no renderizó"
      assert_select "a[href*='view=#{view}'][aria-current='page']"
    end
  end

  # `ApplicationViewComponentPreview`'s request stub said `path: "/lookbook"`, so Pagy built every
  # page link against Lookbook's home: clicking "2" took the reader out of the component they were
  # looking at (#756). A preview has no single URL —it is served at `/lookbook/preview/...` and
  # inside the inspector's iframe— so the right answer is a relative href and not another path
  # written by hand.
  def test_a_paginated_preview_keeps_its_page_links_inside_the_preview
    studio = Tenant.create!(name: "Paginated Studio")
    6.times { |i| studio.movies.create!(name: "Paginated Movie #{i}", status: 0) }

    get "/lookbook/preview/bali/data_table/with_pagination"
    assert_response :ok
    assert_select "nav.pagy-nav-daisyui a[href=?]", "?page=2"
    assert_select "nav.pagy-nav-daisyui a[href^='/lookbook']", false,
      "los links de página sacan al lector de la preview"
  end
end
