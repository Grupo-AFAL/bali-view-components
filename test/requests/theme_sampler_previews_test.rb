# frozen_string_literal: true

require "test_helper"

# Los previews del ThemeSampler son la puerta de revisión visual de los temas
# empaquetados (#718): cada tema renderiza el mismo muestrario bajo su propio
# layout, que estampa data-theme en <html>. Nada más los ejercita — los tests
# de componente no renderizan previews y Cypress no los visita — así que sin
# esto un layout borrado o un preview roto deja la puerta 500eando en verde.
class ThemeSamplerPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "/lookbook/preview/bali/theme_sampler/costa_norte" => "costa-norte",
    "/lookbook/preview/bali/theme_sampler/afal/default" => "afal",
    "/lookbook/preview/bali/theme_sampler/afal_dark/default" => "afal-dark"
  }.freeze

  def test_each_theme_preview_renders_under_its_theme
    PREVIEWS.each do |path, theme|
      get path
      assert_response :ok, "#{path} no renderizó"
      assert_select "html[data-theme=?]", theme
      assert_select "section h2", { text: "Color Palette" },
                    "#{path} renderizó sin el muestrario"
    end
  end
end
