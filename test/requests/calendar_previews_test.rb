# frozen_string_literal: true

require "test_helper"

# The `+mobile` template is only reached through a request variant, and no preview set one: it
# raised without `template:` and nothing went red.
class CalendarPreviewsTest < ActionDispatch::IntegrationTest
  def test_the_mobile_preview_renders_the_phone_template_without_events
    get "/lookbook/preview/bali/calendar/mobile"

    assert_response :ok
    assert_select ".calendar-component .day-view"
  end
end
