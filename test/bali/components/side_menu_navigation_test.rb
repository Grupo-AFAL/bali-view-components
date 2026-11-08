# frozen_string_literal: true

require "test_helper"

class BaliSideMenuNavigationTest < ComponentTestCase
  NAVIGATION = Class.new(Bali::Navigation::Base) do
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

  test "a module whose landing resolves to nil gets no switch" do
    navigation = Class.new(Bali::Navigation::Base) do
      app_module(:work, title: "Work") { item :projects, title: "Projects", path: "/projects" }
      app_module(:admin, title: "Administration") { item :users, title: "Users", path: "/admin/users" }
      app_module(:archive, title: "Archive") { item :old, title: "Old", path: -> { } }
    end
    render_inline(Bali::SideMenu::Component.new(current_path: "/elsewhere", navigation: navigation))

    assert_selector ".dropdown-content a[href='/projects']", text: "Work", visible: :all
    assert_no_selector ".dropdown-content a", text: "Archive", visible: :all
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
    nav = Class.new(Bali::Navigation::Base) do
      section(:people, title: "People") { item :pasaporte, title: "Pasaporte", path: -> { nil } }
    end
    render_inline(Bali::SideMenu::Component.new(current_path: "/", navigation: nav))

    assert_selector "a.side-menu-expanded[href='#'][disabled]", text: "Pasaporte"
  end

  test "a group's badge is drawn on its row as with_item draws it, and nil draws none" do
    nav = Class.new(Bali::Navigation::Base) do
      section :data, title: "Data" do
        group :pending, title: "Pending", icon: "inbox", badge: -> { 3 } do
          item :discrepancies, title: "Discrepancies", path: "/discrepancies"
        end
        group :explore, title: "Explore", badge: -> { } do
          item :catalog, title: "Catalog", path: "/catalog"
        end
      end
    end
    render_inline(Bali::SideMenu::Component.new(current_path: "/", navigation: nav))
    drawn = page.find(".collapse-title", text: "Pending").native.to_html

    assert_selector ".collapse-title .rounded-box", text: "3"
    assert page.find(".collapse-title", text: "Explore").has_no_css?(".rounded-box")

    render_inline(Bali::SideMenu::Component.new(current_path: "/")) do |menu|
      menu.with_list(title: "Data") do |list|
        list.with_item(name: "Pending", icon: "inbox", badge: 3) do |group|
          group.with_item(name: "Discrepancies", href: "/discrepancies")
        end
      end
    end
    assert_equal page.find(".collapse-title", text: "Pending").native.to_html, drawn
  end

  test "an item's link_class lands on its link, in a group too" do
    nav = Class.new(Bali::Navigation::Base) do
      section :documents, title: "Documents" do
        item :templates, title: "Templates", icon: "file", path: "/templates", link_class: "line-through opacity-60"
        item :portal, title: "Portal", icon: "network", path: "/portal"
        group :configuration, title: "Configuration" do
          item :glossary, title: "Glossary", path: "/glossary", link_class: "line-through opacity-60"
        end
      end
    end
    render_inline(Bali::SideMenu::Component.new(current_path: "/", navigation: nav))

    assert_selector "a.side-menu-expanded.line-through.opacity-60[href='/templates']", text: "Templates"
    assert_selector ".collapse-content a.line-through.opacity-60[href='/glossary']", text: "Glossary"
    assert_selector "a.side-menu-expanded[href='/portal']:not(.line-through)", text: "Portal"
  end

  test "a group with item_icons: false draws its items as a hand-written group without icons" do
    nav = Class.new(Bali::Navigation::Base) do
      section :documents, title: "Documents" do
        group :supervision, title: "Supervision", icon: "users", item_icons: false do
          item :team, title: "Team", icon: "users-round", path: "/team"
          item :control, title: "Control", icon: "clipboard-check", path: "/control"
        end
        group :explore, title: "Explore", icon: "compass" do
          item :catalog, title: "Catalog", icon: "folder-tree", path: "/catalog"
        end
      end
    end
    render_inline(Bali::SideMenu::Component.new(current_path: "/", navigation: nav))
    drawn = page.all(".side-menu-list > li").first.native.inner_html

    assert_no_selector ".collapse-content a[href='/team'] svg"
    assert_no_selector ".side-menu-collapsed-flyout a[href='/team'] svg", visible: :all
    assert_selector ".collapse-content a[href='/catalog'] svg"

    render_inline(Bali::SideMenu::Component.new(current_path: "/")) do |menu|
      menu.with_list(title: "Documents") do |list|
        list.with_item(name: "Supervision", icon: "users") do |group|
          group.with_item(name: "Team", href: "/team", match: :crud)
          group.with_item(name: "Control", href: "/control", match: :crud)
        end
      end
    end
    assert_equal page.all(".side-menu-list > li").first.native.inner_html, drawn
  end

  test "the block's lists come after the navigation's" do
    render_menu do |menu|
      menu.with_list(title: "Shortcuts") { |list| list.with_item(name: "Help", href: "/help") }
    end

    assert_equal %w[Work Shortcuts], page.all(".sidebar-menu .menu-label").map(&:text).map(&:strip)
  end
end
