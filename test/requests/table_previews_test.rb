# frozen_string_literal: true

require "test_helper"

# El id duplicado de #1157 se vio en el navegador, sobre un preview de Lookbook, y ni un solo
# test lo miraba por ahí: los tests de componente renderizan la clase, no la página servida.
# Esto cierra ese hueco por el camino donde apareció — dos previews de `Table` que pasan `id:`,
# pedidos por HTTP y revisados entero el documento, no sólo la `<table>`.
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

  # El reparto concreto: el id va al `<div class="table-component">`, y ninguna `<table>` de la
  # página lleva uno. Sin esto, la aserción de arriba seguiría verde si alguien moviera el id a
  # la `<table>` y se lo quitara al contenedor.
  def test_the_container_id_preview_puts_the_id_on_the_wrapper_and_not_on_the_table
    get "/lookbook/preview/bali/table/with_container_id"
    assert_response :ok

    assert_select "div#inventory.table-component", 1
    assert_select "table[id]", false, "ninguna `<table>` debería llevar id propio"
  end
end
