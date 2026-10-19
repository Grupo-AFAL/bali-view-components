# frozen_string_literal: true

require "test_helper"

# The Lookbook previews of Bali::Topbar::Inbox render, and the default one points the popover at
# the dummy's real endpoint, which is what Cypress opens.
class TopbarInboxPreviewsTest < ActionDispatch::IntegrationTest
  def test_the_default_preview_renders_the_icon_with_its_popover_url
    get "/lookbook/preview/bali/topbar/inbox/default"

    assert_response :success
    assert_select "[data-controller=topbar-inbox][data-topbar-inbox-popover-url-value='/inbox/popover']"
  end

  def test_the_states_preview_renders_every_counter
    get "/lookbook/preview/bali/topbar/inbox/states"

    assert_response :success
    assert_select "a.bali-topbar-inbox-trigger", 5
  end
end
