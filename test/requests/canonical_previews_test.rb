# frozen_string_literal: true

require "test_helper"

# El preview canónico es el entregable de esta release ("copiá esta composición"), pero vive
# fuera del alcance de todo lo demás: los tests de componente lo saltean (renderizan clases,
# no previews) y Cypress solo visita `/bali/data_table/*`. Sin esto, el pegamento propio de
# IndexPage —el include de `Bali::DataTable::Preview::CanonicalIndex`, el `render partial:`
# que cruza de directorio, los dos archivos en `do_not_eager_load`— puede 500ear entero y la
# suite sigue verde.
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
end
