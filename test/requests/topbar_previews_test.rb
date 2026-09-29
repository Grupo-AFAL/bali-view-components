# frozen_string_literal: true

require "test_helper"

# IconAction's `label:` → `aria_label:` rename (beta.14) reached the component and its tests, but not
# two of the Topbar's previews — and nothing went red because the suite tests the class, not its
# preview templates (#1035). Same as IconPreviewsTest: requesting each preview over HTTP is the only
# path where a broken template shows.
class TopbarPreviewsTest < ActionDispatch::IntegrationTest
  # One `def` in Bali::Topbar::Preview per entry; with no `@!group`, each one is a URL.
  PREVIEWS = %w[
    default
    search_only
    without_search
    without_mobile_trigger
    user_menu
    icon_actions
    tools_menu
  ].freeze

  def test_every_topbar_preview_renders_over_the_request_path
    PREVIEWS.each do |name|
      get "/lookbook/preview/bali/topbar/#{name}"
      assert_response :ok, "/lookbook/preview/bali/topbar/#{name} no renderizó"
    end
  end
end
