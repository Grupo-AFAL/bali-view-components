# frozen_string_literal: true

require "test_helper"

# The two Topbar previews render the widget from a template, which the component tests never
# load: requesting them over HTTP is the only path where a broken one shows.
class FeedbackWidgetPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "default" => "button.fixed",
    "topbar_icon" => ".bali-topbar button",
    "topbar_labeled" => ".bali-topbar button"
  }.freeze

  def test_every_feedback_widget_preview_renders_its_trigger
    PREVIEWS.each do |name, trigger|
      get "/lookbook/preview/bali/feedback_widget/#{name}"

      assert_response :ok, "/lookbook/preview/bali/feedback_widget/#{name} did not render"
      assert_select "#{trigger}[data-action='feedback-widget#open']"
    end
  end
end
