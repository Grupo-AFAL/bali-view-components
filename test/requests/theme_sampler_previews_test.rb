# frozen_string_literal: true

require "test_helper"

# The ThemeSampler previews are the visual review gate for the packaged themes (#718): each theme
# renders the same sampler under its own layout, which stamps data-theme on <html>. Nothing else
# exercises them — the component tests render no previews and Cypress does not visit them — so
# without this a deleted layout or a broken preview leaves the gate 500ing in green.
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
