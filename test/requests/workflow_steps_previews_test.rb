# frozen_string_literal: true

require "test_helper"

# Las previews de este componente no las miraba nadie por la ruta HTTP: las
# suites de `test/requests/` son listas explícitas, no un barrido, y los tests
# de componente renderizan clases, no previews. Ese hueco es el que deja pasar
# la trampa de `Module.nesting` que documenta `.claude/CLAUDE.md` —un
# `preview.rb` que nombra una constante hermana sin calificar resuelve bien con
# `bin/rails runner` y 500ea por la request, después de un `reload!`—, y
# también cualquier error de la plantilla de una preview, que sólo se ve
# abriendo Lookbook.
#
# El guard estático de `icon_previews_test.rb` cubre la mitad de constantes;
# esto cubre la otra, que es que las cinco previews efectivamente rinden.
class WorkflowStepsPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[default horizontal rail decision_pattern provisional_route].freeze

  def test_every_workflow_steps_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/workflow_steps/#{name}"
      assert_response :ok, "/lookbook/preview/bali/workflow_steps/#{name} no renderizó"
      assert_select ".workflow-steps", { minimum: 1 },
        "/lookbook/preview/bali/workflow_steps/#{name} renderizó sin el componente"
    end
  end

  # Las tres formas salen de la misma clase raíz, así que una preview que
  # rinde no prueba que rinda la forma que dice rendir.
  def test_each_preview_renders_the_shape_it_documents
    { "default" => "ol.workflow-steps.workflow-steps-vertical",
      "horizontal" => "div.workflow-steps.workflow-steps-horizontal",
      "rail" => "div.workflow-steps.workflow-steps-rail" }.each do |name, selector|
      get "/lookbook/preview/bali/workflow_steps/#{name}"
      assert_response :ok
      assert_select selector, { minimum: 1 }, "#{name} no rindió #{selector}"
    end
  end

  # El riel es la única forma que puede desbordar, y su `<ol>` es el contenedor
  # de scroll: sin `tabindex` no hay forma de alcanzarlo con el teclado. Se
  # comprueba por la request y no sólo en el test de componente porque es lo
  # que un lector va a ver en Lookbook.
  def test_the_rail_preview_keeps_its_scroll_container_reachable
    get "/lookbook/preview/bali/workflow_steps/rail"
    assert_response :ok
    assert_select "ol.workflow-steps-list[tabindex='0'][aria-label]", { minimum: 1 }
  end

  # El toggle de la preview es el que documenta que en el riel la barra viene
  # apagada y se enciende a pedido.
  def test_the_rail_preview_toggles_the_progress_bar
    get "/lookbook/preview/bali/workflow_steps/rail"
    assert_response :ok
    assert_select ".workflow-steps-rail .workflow-steps-progress", false,
      "el riel dibujó la barra N/M sin que se la pidieran"

    get "/lookbook/preview/bali/workflow_steps/rail", params: { progress: true }
    assert_response :ok
    assert_select ".workflow-steps-rail .workflow-steps-progress", { minimum: 1 }
  end
end
