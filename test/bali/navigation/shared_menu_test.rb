# frozen_string_literal: true

require "test_helper"

# The side menu and the palette of one page read one menu: view_component hands every component
# the view it was first rendered from (`ViewComponent::Base#helpers`), and `navigation_for`
# memoizes on that view. A bump that changed either would run every gate twice.
class NavigationSharedMenuTest < ActionView::TestCase
  GATES = []

  NAVIGATION = Class.new(Bali::Navigation::Base) do
    current_controller_path { "projects" }

    app_module :work, title: "Work", icon: "briefcase" do
      item :projects, title: "Projects", path: "/projects", controllers: %w[projects], gate: -> { GATES << :projects }
      item :calendar, title: "Calendar", path: "/calendar", gate: -> { GATES << :calendar }
    end
    app_module :admin, title: "Administration", icon: "shield", gate: -> { GATES << :admin } do
      item :users, title: "Users", path: "/admin/users", gate: -> { GATES << :users }
    end
  end

  setup { GATES.clear }

  test "a page with both components runs each gate once" do
    render inline: <<~ERB, locals: { navigation: NAVIGATION }
      <%= render Bali::SideMenu::Component.new(current_path: "/projects", navigation: navigation) %>
      <%= render Bali::Command::Component.new(navigation: navigation) %>
    ERB

    assert_includes rendered, "Projects"
    assert_equal %i[admin calendar projects users], GATES.sort
  end
end
