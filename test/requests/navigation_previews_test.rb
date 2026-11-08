# frozen_string_literal: true

require "test_helper"

# The two previews drawn from a `Bali::Navigation::Base` subclass, over the request path: the navigation is a
# class declared inside a preview file, which is what Lookbook reloads.
class NavigationPreviewsTest < ActionDispatch::IntegrationTest
  SIDE_MENU = "/lookbook/preview/bali/side_menu/from_navigation"
  COMMAND = "/lookbook/preview/bali/command/from_navigation"

  test "the side menu marks the item of the controller the request counts as" do
    get SIDE_MENU
    assert_response :ok
    assert_select "a.side-menu-expanded.active[aria-current=page][href='/projects']", text: /Projects/

    get SIDE_MENU, params: { controller_path: "admin/users" }
    assert_select ".menu-switcher-trigger", text: /Administration/
    assert_select "a.side-menu-expanded.active[aria-current=page][href='/admin/users']", text: /Users/
  end

  test "the side menu draws a group's badge and an item's link class" do
    get SIDE_MENU
    assert_select ".collapse-title", text: /Settings\s*2/
    assert_select "a.side-menu-expanded.line-through.opacity-60[href='/reports/archive']", text: /Archive/
  end

  test "the palette offers the frequent pages, the modules, the pages, and the block's group after them" do
    get COMMAND
    assert_response :ok

    assert_equal %w[Frequent Modules Pages Actions], css_select(".cmd-group").map { it.text.strip }
    assert_equal %w[/projects /inbox /admin/users],
                 css_select("[data-command-target=row][data-mode=recent]").map { it["data-href"] }
    assert_select "[data-command-target=row][data-href='/reports/exports']", text: /Exports/
  end
end
