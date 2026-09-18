# frozen_string_literal: true

require "test_helper"

# Los tres previews de la superficie de celda (#1146) son la única prueba de que
# la celda se ve como dice la documentación, y nada más los ejercita: los tests
# de componente renderizan clases, no previews, y Cypress no visita StatCard.
# Un preview que 500ea —una constante hermana mal escrita, un parcial movido—
# deja la galería rota con Minitest en verde, que es justo lo que avisa
# `.claude/CLAUDE.md` sobre el autoloading de previews.
class StatCardPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    # El caso del issue: la rejilla de cifras DENTRO de la tarjeta de sección.
    "/lookbook/preview/bali/stat_card/cells_in_card" => 6,
    # Las tres cajas lado a lado; sólo una es celda.
    "/lookbook/preview/bali/stat_card/surfaces_compared" => 1,
    "/lookbook/preview/bali/stat_card/emphasised_cell" => 1
  }.freeze

  def test_each_cell_preview_renders_its_cells
    PREVIEWS.each do |path, cells|
      get path
      assert_response :ok, "#{path} no renderizó"
      assert_select ".rounded-box.border.p-4", { count: cells },
                    "#{path} renderizó #{cells} celdas distintas de las esperadas"
    end
  end

  # La regla de la casa que la celda existe para cumplir: dentro de la tarjeta de
  # una sección no puede haber otra tarjeta. La única `.card` de la página es la
  # de la sección.
  def test_the_grid_of_cells_emits_exactly_one_card
    get "/lookbook/preview/bali/stat_card/cells_in_card"

    assert_response :ok
    assert_select ".card", { count: 1 }, "la rejilla emitió tarjetas anidadas"
    assert_select ".stat", false, "la celda emitió el markup .stat de daisyUI"
  end

  # El parámetro con el que la guía mide su propia afirmación sobre `value_class:`
  # («se concatena; un tamaño ahí gana, salvo text-2xl»): si desaparece, la
  # medición de la doc deja de ser reproducible desde la galería.
  def test_the_emphasised_cell_preview_takes_a_value_class
    get "/lookbook/preview/bali/stat_card/emphasised_cell", params: { value_class: "text-xl" }

    assert_response :ok
    assert_select "p.text-3xl.font-bold.text-xl", { count: 1 }
  end
end
