# frozen_string_literal: true

require "test_helper"

class BaliCommandNavigationTest < ComponentTestCase
  WITH_MODULES = Class.new(Bali::Navigation) do
    app_module :work, title: "Work", icon: "briefcase" do
      item :projects, title: "Projects", icon: "folder", path: "/projects"
      item :catalog, title: "Catalog", path: "https://apex.example", target: "_blank"
      item :schedules, title: "Schedules", path: "/schedules", menu: false, keywords: "cadences"
    end
    app_module :admin, title: "Administration", icon: "shield", landing: "/admin" do
      item :users, title: "Users", icon: "users", path: "/admin/users"
    end
  end

  WITH_SECTIONS = Class.new(Bali::Navigation) do
    section :monitoring, title: "Monitoring" do
      item :events, title: "Events", icon: "inbox", path: "/events", hint: "Webhook events"
    end
  end

  def groups
    page.all("[data-command-target='group']", visible: :all).map do |group|
      [ group.find(".cmd-group", visible: :all).text(:all).strip, group["data-mode"] ]
    end
  end

  test "with modules: a group of modules on open, then the pages as you type" do
    render_inline(Bali::Command::Component.new(navigation: WITH_MODULES))

    assert_equal [ [ "Modules", "navigation" ], [ "Pages", "searchable" ] ], groups
    assert_selector "[data-mode='navigation'][data-href='/projects']", text: "Work", visible: :all
    assert_selector "[data-mode='navigation'][data-href='/admin']", text: "Administration", visible: :all
  end

  test "without modules: one group of pages, on open, named by their section" do
    render_inline(Bali::Command::Component.new(navigation: WITH_SECTIONS))

    assert_equal [ [ "Pages", "navigation" ] ], groups
    assert_selector "[data-href='/events'][data-search='events monitoring webhook events']", text: "Monitoring",
                                                                                             visible: :all
  end

  test "pages: an item opening elsewhere stays out, one only for the palette is in" do
    render_inline(Bali::Command::Component.new(navigation: WITH_MODULES))

    assert_selector "[data-mode='searchable'][data-href='/schedules'][data-search='schedules work cadences']",
                    visible: :all
    assert_no_selector "[data-href='https://apex.example']", visible: :all
  end

  test "the block's groups come after the navigation's" do
    render_inline(Bali::Command::Component.new(navigation: WITH_SECTIONS)) do |c|
      c.with_group(name: "Actions") { |group| group.with_item(title: "New event", href: "/events/new") }
    end

    assert_equal %w[Pages Actions], groups.map(&:first)
  end

  test "the group names are Bali's translation" do
    I18n.with_locale(:es) { render_inline(Bali::Command::Component.new(navigation: WITH_MODULES)) }

    assert_equal %w[Módulos Páginas], groups.map(&:first)
  end
end
