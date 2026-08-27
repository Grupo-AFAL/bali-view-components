# frozen_string_literal: true

require "test_helper"

# #1097. The unit test pins what `conditionally_skip_layout` RETURNS; this pins what Rails
# then does with it, which is the half the defect lived in: `layout :a_symbol` compiled to
# "nil means look up `layouts/application`", that lookup always hit, and the
# `layout -> { "turbo_rails/frame" if turbo_frame_request? }` turbo-rails declares on
# ActionController::Base was unreachable for every app that included the concern.
#
# The dummy's admin controllers are the fixture that makes it visible: they declare
# `self.conditional_layout = "admin"`, so a frame request had to beat a layout that IS
# declared, not just the implied one.
class LayoutConcernRequestTest < ActionDispatch::IntegrationTest
  APP_SHELL = ".app-layout-main"

  def setup
    @studio = Studio.create!(name: "Frame Studio", country: "Mexico", status: :active)
  end

  def test_an_ordinary_request_gets_the_whole_app_shell
    get admin_studio_path(@studio)

    assert_response :ok
    assert_select APP_SHELL
  end

  def test_a_turbo_frame_request_gets_the_frame_layout_instead_of_the_shell
    get admin_studio_path(@studio), headers: { "Turbo-Frame" => "detail" }

    assert_response :ok
    assert_select APP_SHELL, false, "a frame response must not carry the app shell"
    # ... but it IS a layout, and the only other one that renders a bare `<head>` with no
    # app chrome in it is turbo-rails'.
    assert_select "head"
    assert_select "body:not([class])"
    assert_select ".show-page-component"
  end

  # The overlay wins over the frame: `false` is smaller than the frame layout, and a
  # response headed for a drawer does not want its `<html>` either.
  def test_a_drawer_fetch_beats_the_frame
    get admin_studio_path(@studio), params: { layout: "false" },
                                    headers: { "Turbo-Frame" => "detail" }

    assert_response :ok
    assert_select "body", false, "the drawer fetch must not carry a layout at all"
    assert_select ".show-page-component"
  end
end
