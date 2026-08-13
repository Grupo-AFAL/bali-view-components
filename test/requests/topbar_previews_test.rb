# frozen_string_literal: true

require "test_helper"

# El rename `label:` → `aria_label:` de IconAction (beta.14) llegó al componente y a sus
# tests, pero no a dos de los previews del Topbar — y nada se puso en rojo porque el suite
# prueba la clase, no sus templates de preview (#1035). Igual que IconPreviewsTest: pedir
# cada preview por HTTP es el único camino donde un template roto se manifiesta.
class TopbarPreviewsTest < ActionDispatch::IntegrationTest
  # Los seis `def` de Bali::Topbar::Preview; sin `@!group`, cada uno es una URL.
  PREVIEWS = %w[
    default
    search_only
    without_search
    without_mobile_trigger
    user_menu
    icon_actions
  ].freeze

  def test_every_topbar_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/topbar/#{name}"
      assert_response :ok, "/lookbook/preview/bali/topbar/#{name} no renderizó"
    end
  end
end
