# frozen_string_literal: true

require "test_helper"

# The guide's first example runs as written, and it is the navigation the previews draw.
class NavigationGuideExampleTest < ActiveSupport::TestCase
  GUIDE = File.expand_path("../../../docs/guides/navigation.md", __dir__)

  def guide_navigation
    code = File.read(GUIDE)[/```ruby\n(.*?)```/m, 1]
    Module.new.tap { it.module_eval(code, GUIDE) }.const_get(:Navigation)
  end

  def projection(navigation)
    navigation.nodes.map { [ it.class, it.key, it.title, it.controllers, it.try(:path), it.try(:hint), it.try(:menu?) ] }
  end

  test "the guide's first navigation declares what the previews draw" do
    assert_equal projection(Bali::SideMenu::Preview::DemoNavigation), projection(guide_navigation)
    assert_equal :members, guide_navigation.locate("settings/members").item.key
  end
end
