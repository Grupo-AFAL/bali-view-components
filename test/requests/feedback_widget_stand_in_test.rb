# frozen_string_literal: true

require "test_helper"

# Every admin page carries the FeedbackWidget, and the widget asks for its badge as it connects.
# Pointed at an Opina that is not running, that was a refused connection in the console of every
# admin page a browser check opened (#1303).
class FeedbackWidgetStandInTest < ActionDispatch::IntegrationTest
  def test_the_admin_layout_widget_asks_this_app_for_its_badge
    get "/admin/studios"

    badge_url = css_select("[data-feedback-widget-badge-url-value]").sole["data-feedback-widget-badge-url-value"]
    assert_equal "http://www.example.com/api/v1/projects/bali-demo/badge", badge_url

    get badge_url
    assert_response :ok
    assert_equal({ "unread_count" => 0 }, response.parsed_body)
  end
end
