# frozen_string_literal: true

require "test_helper"

class BaliSideMenuNavigationTest < ComponentTestCase
  NAVIGATION = Class.new(Bali::Navigation) do
    current_controller_path { "projects/tasks" }

    app_module :work, title: "Work", icon: "briefcase", controllers: %w[projects] do
      item :projects, title: "Projects", icon: "folder", path: "/projects", controllers: %w[projects]
      item :calendar, title: "Calendar", icon: "calendar", path: "/calendar", hint: "Team calendar"
      group :settings, title: "Settings", icon: "settings" do
        item :members, title: "Members", path: "/settings/members"
      end
      item :schedules, title: "Schedules", path: "/schedules", menu: false
      section :reports, title: "Reports", heading: false do
        item :monthly, title: "Monthly", icon: "chart-pie", path: "/reports/monthly"
      end
    end

    app_module :admin, title: "Administration", icon: "shield", landing: "/admin" do
      item :users, title: "Users", icon: "users", path: "/admin/users"
    end
  end

  def render_menu(&)
    render_inline(Bali::SideMenu::Component.new(current_path: "/elsewhere", navigation: NAVIGATION), &)
  end

  test "a switch per module, landing on its first item or on its landing" do
    render_menu

    assert_selector ".menu-switcher-trigger", text: "Work"
    assert_selector ".dropdown-content a[href='/projects']", text: "Work", visible: :all
    assert_selector ".dropdown-content a[href='/admin']", text: "Administration", visible: :all
  end

  test "the lists of the current module, a section without heading drawn without one" do
    render_menu

    assert_equal [ "Work" ], page.all(".sidebar-menu .menu-label").map(&:text).map(&:strip)
    assert_selector ".sidebar-menu a[href='/reports/monthly']", text: "Monthly"
    assert_no_selector ".sidebar-menu a[href='/admin/users']"
    assert_no_selector ".sidebar-menu a[href='/schedules']"
  end

  test "a group holds its items" do
    render_menu

    assert_selector ".collapse-title", text: "Settings"
    assert_selector ".collapse-content a[href='/settings/members']", text: "Members"
  end

  test "the item the controller belongs to is active though its path does not match" do
    render_menu

    assert_selector "a.side-menu-expanded.active[href='/projects'][aria-current='page']"
    assert_no_selector "a.side-menu-expanded.active[href='/calendar']"
  end

  test "a hint is the link's title, and only an item with one carries it" do
    render_menu

    assert_selector "a.side-menu-expanded[href='/calendar'][title='Team calendar']"
    assert_no_selector "a.side-menu-expanded[href='/projects'][title]"
  end

  test "an item whose path resolves to nil is drawn disabled" do
    nav = Class.new(Bali::Navigation) do
      section(:people, title: "People") { item :pasaporte, title: "Pasaporte", path: -> { nil } }
    end
    render_inline(Bali::SideMenu::Component.new(current_path: "/", navigation: nav))

    assert_selector "a.side-menu-expanded[href='#'][disabled]", text: "Pasaporte"
  end

  test "the block's lists come after the navigation's" do
    render_menu do |menu|
      menu.with_list(title: "Shortcuts") { |list| list.with_item(name: "Help", href: "/help") }
    end

    assert_equal %w[Work Shortcuts], page.all(".sidebar-menu .menu-label").map(&:text).map(&:strip)
  end
end
