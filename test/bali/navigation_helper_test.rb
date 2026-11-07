# frozen_string_literal: true

require "test_helper"

class NavigationHelperTest < ActionView::TestCase
  include Bali::NavigationHelper

  NAVIGATION = Class.new(Bali::Navigation::Base) do
    section :work, title: "Work" do
      item :dashboard, title: "Dashboard", path: :root_path, gate: -> { signed_in? }
    end
  end

  def signed_in? = true

  test "one menu per navigation and view, whose gates and paths run in the view" do
    menu = navigation_for(NAVIGATION)

    assert_same menu, navigation_for(NAVIGATION)
    assert_equal [ "/" ], menu.sections.flat_map { menu.items(it) }.map { menu.path(it) }
  end
end
