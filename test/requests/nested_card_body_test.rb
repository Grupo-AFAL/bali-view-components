# frozen_string_literal: true

require "test_helper"

# `Bali::Card::Component` ya emite su propio `.card-body` (`component.html.erb:4`) y acepta
# `body_class:` para las clases extra que quiera el call site. Una preview que además escribe su
# propio `<div class="card-body">` deja el contenido dentro de dos, y el padding se duplica:
# daisyUI declara `.card-body { padding: var(--card-p, 1.5rem) }` y nadie fija `--card-p` en el
# tamaño `md`, así que la tarjeta salía con 48px por lado en vez de 24px (#833).
#
# Va por HTTP y no por `assert_selector` de componente a propósito: el defecto vive en la
# composición de la preview, no en el componente. Un test de componente renderiza
# `Bali::Card::Component` sola y siempre ve un solo `.card-body`, así que nunca lo vería. Y una
# preview es lo que un host copia, que es lo que hace que valga la pena fijarlo.
class NestedCardBodyTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[
    /lookbook/preview/bali/dashboard_page/default
    /lookbook/preview/bali/form_page/default
    /lookbook/preview/bali/form_page/with_sidebar
  ].freeze

  def test_no_preview_nests_one_card_body_inside_another
    PREVIEWS.each do |path|
      get path
      assert_response :ok, "#{path} no renderizó"
      assert_select ".card-body", { minimum: 1 },
        "#{path} renderizó sin ningún .card-body: el test pasaría en vacío"
      assert_select ".card-body .card-body", false,
        "#{path} anida un .card-body dentro de otro — padding doble (#833)"
    end
  end

  # El request test de arriba fija tres previews. Esto fija la REGLA: `Bali::Card::Component` es
  # la única que puede escribir `card-body`, y ninguna de las ~464 previews del paquete tiene por
  # qué escribirlo a mano. Es instantáneo, así que una preview nueva queda cubierta sin que nadie
  # se acuerde de sumarla a `PREVIEWS`.
  def test_no_preview_template_writes_a_card_body_by_hand
    root = Bali::Engine.root.join("app/components/bali")
    offenders = Dir[root.join("**/previews/*.erb")].select do |file|
      File.read(file).include?("card-body")
    end

    assert_empty offenders.map { |f| f.delete_prefix("#{Bali::Engine.root}/") },
      "escriben `card-body` a mano; usá el `body_class:` de Bali::Card::Component"
  end
end
