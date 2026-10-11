# frozen_string_literal: true

require "test_helper"

# The component tests render the class, not the previews; requesting each one over HTTP is
# the only path where a broken preview shows.
class LegendPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = %w[default custom_colors swatches].freeze

  def test_every_legend_preview_renders_a_legend
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/legend/#{name}"
      assert_response :ok, "/lookbook/preview/bali/legend/#{name} did not render"
      assert_select "ul[role=list] > li.legend-item", { minimum: 1 }, "#{name} rendered no entries"
    end
  end
end
