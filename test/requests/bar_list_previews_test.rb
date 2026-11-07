# frozen_string_literal: true

require "test_helper"

# The component tests render the class, not the previews; requesting each one over HTTP is
# the only path where a broken preview shows.
class BarListPreviewsTest < ActionDispatch::IntegrationTest
  # path => [rows, links]
  PREVIEWS = {
    "default" => [ 3, 3 ],
    "default?rows=12" => [ 12, 11 ],
    "default?links=false" => [ 3, 0 ],
    "long_labels" => [ 3, 2 ],
    "formatted" => [ 3, 0 ]
  }.freeze

  def test_every_bar_list_preview_renders_its_rows
    PREVIEWS.each do |path, (rows, links)|
      get "/lookbook/preview/bali/bar_list/#{path}"
      assert_response :ok, "/lookbook/preview/bali/bar_list/#{path} did not render"
      assert_select "ul.bar-list[role=list] > li", { count: rows }, "#{path} rendered the wrong number of rows"
      assert_select "ul.bar-list > li > a[href]", { count: links }, "#{path} rendered the wrong number of links"
    end
  end
end
