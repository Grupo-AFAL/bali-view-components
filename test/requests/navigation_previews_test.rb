# frozen_string_literal: true

require "test_helper"

# The two previews drawn from a `Bali::Navigation`, over the request path: the navigation is a
# class declared inside a preview file, which is what Lookbook reloads.
class NavigationPreviewsTest < ActionDispatch::IntegrationTest
  SIDE_MENU = "/lookbook/preview/bali/side_menu/from_navigation"

  test "the side menu marks the item of the controller the request counts as" do
    get SIDE_MENU
    assert_response :ok
    assert_select "a.side-menu-expanded.active[aria-current=page][href='/projects']", text: /Projects/

    get SIDE_MENU, params: { controller_path: "admin/users" }
    assert_select ".menu-switcher-trigger", text: /Administration/
    assert_select "a.side-menu-expanded.active[aria-current=page][href='/admin/users']", text: /Users/
  end
end
