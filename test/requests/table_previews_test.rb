# frozen_string_literal: true

require "test_helper"

# #1157's duplicate id was seen in the browser, over a Lookbook preview, and not a single test
# looked at it from there: component tests render the class, not the served page. This closes that
# gap along the path it appeared on — two `Table` previews that pass `id:`, requested over HTTP and
# checked over the whole document, not just the `<table>`.
class TablePreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[
    /lookbook/preview/bali/table/with_container_id
    /lookbook/preview/bali/table/collapsible_groups
  ].freeze

  def test_the_previews_that_pass_an_id_render_without_repeating_one
    PREVIEWS.each do |path|
      get path
      assert_response :ok, "#{path} no renderizó"

      ids = Nokogiri::HTML5(response.body).css("[id]").map { |node| node["id"] }
      repeated = ids.tally.select { |_id, count| count > 1 }.keys
      assert_empty(repeated, "#{path} repite ids: #{repeated.inspect}")
    end
  end

  # The concrete split: the id goes on the `<div class="table-component">`, and no `<table>` on the
  # page carries one. Without this, the assertion above would stay green if somebody moved the id to
  # the `<table>` and took it off the container.
  def test_the_container_id_preview_puts_the_id_on_the_wrapper_and_not_on_the_table
    get "/lookbook/preview/bali/table/with_container_id"
    assert_response :ok

    assert_select "div#inventory.table-component", 1
    assert_select "table[id]", false, "ninguna `<table>` debería llevar id propio"
  end
end
