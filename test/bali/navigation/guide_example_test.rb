# frozen_string_literal: true

require "test_helper"

# The guide's first example runs as written, and it is the navigation the previews draw.
class NavigationGuideExampleTest < ActiveSupport::TestCase
  GUIDE = File.expand_path("../../../docs/guides/navigation.md", __dir__)

  def guide_navigation
    code = File.read(GUIDE)[/```ruby\n(.*?)```/m, 1]
    Module.new.tap { it.module_eval(code, GUIDE) }.const_get(:Navigation)
  end

  test "the guide's first navigation declares what the previews draw" do
    preview = Bali::SideMenu::Preview::DemoNavigation

    assert_equal preview.nodes.map(&:key), guide_navigation.nodes.map(&:key)
    assert_equal :members, guide_navigation.locate("settings/members").item.key
  end
end
