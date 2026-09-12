# frozen_string_literal: true

require "test_helper"

# The react-island previews are plain markup plus the react_island_meta_tags
# helper — no Ruby component. What can break server-side is exactly that glue:
# the helper not being exposed to preview templates (the engine's to_prepare),
# or the digested bundle path not resolving. Cypress covers the mount; this
# pins the 200 and the two contract elements the loader needs on the page.
class ReactIslandPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[
    /lookbook/preview/bali/react_island/default
    /lookbook/preview/bali/react_island/two_islands
    /lookbook/preview/bali/react_island/load_error
  ].freeze

  def test_the_previews_render_the_island_element_and_the_loader_metas
    PREVIEWS.each do |path|
      get path
      assert_response :ok, "#{path} no renderizó"
      assert_select "[data-controller='react-island-demo']", { minimum: 1 },
        "#{path} renderizó sin el elemento de la isla"
      assert_select "meta[name='bali-react-island-demo-js']", { minimum: 1 },
        "#{path} renderizó sin la meta del bundle que el loader necesita"
    end
  end

  def test_values_reach_the_island_element
    get "/lookbook/preview/bali/react_island/default"
    assert_select "[data-react-island-demo-label-value='Visitors']"
    assert_select "[data-react-island-demo-start-value='3']"
  end
end
