# frozen_string_literal: true

require "test_helper"

# A preview reaches the `+mobile` template only through `@display variant mobile`, which the dummy's
# ComponentPreviewsController turns into `request.variant`.
class CalendarPreviewsTest < ActionDispatch::IntegrationTest
  def test_the_mobile_preview_renders_the_phone_template_without_events
    get "/lookbook/preview/bali/calendar/mobile"

    assert_response :ok
    assert_select ".calendar-component .day-view"
  end
end
