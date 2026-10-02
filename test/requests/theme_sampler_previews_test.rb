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
    "/lookbook/preview/bali/theme_sampler/afal_dark/default" => "afal-dark",
    "/lookbook/preview/bali/theme_sampler/costa_norte_dark/default" => "costa-norte-dark"
  }.freeze

  def test_each_theme_preview_renders_under_its_theme
    PREVIEWS.each do |path, theme|
      get path
      assert_response :ok, "#{path} did not render"
      assert_select "html[data-theme=?]", theme
      assert_select "section h2", { text: "Color Palette" },
                    "#{path} rendered without the sampler"
    end
  end

  # Button takes `variant:`; a `color:` falls through to an HTML attribute and paints a plain
  # `btn`, so the sampler showed no primary, secondary or accent button to review.
  def test_each_theme_preview_paints_its_brand_buttons
    PREVIEWS.each_key do |path|
      get path
      %w[primary secondary accent].each do |variant|
        assert_select "button.btn-#{variant}", { text: variant.capitalize },
                      "#{path} has no #{variant} button"
      end
    end
  end
end
