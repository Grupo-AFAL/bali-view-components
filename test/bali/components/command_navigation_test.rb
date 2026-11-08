# frozen_string_literal: true

require "test_helper"

class BaliCommandNavigationTest < ComponentTestCase
  WITH_MODULES = Class.new(Bali::Navigation::Base) do
    app_module :work, title: "Work", icon: "briefcase" do
      item :projects, title: "Projects", icon: "folder", path: "/projects"
      item :catalog, title: "Catalog", path: "https://apex.example", target: "_blank"
      item :schedules, title: "Schedules", path: "/schedules", menu: false, keywords: "cadences"
    end
    app_module :admin, title: "Administration", icon: "shield", landing: "/admin" do
      item :users, title: "Users", icon: "users", path: "/admin/users"
    end
  end

  WITH_SECTIONS = Class.new(Bali::Navigation::Base) do
    section :monitoring, title: "Monitoring" do
      item :events, title: "Events", icon: "inbox", path: "/events", hint: "Webhook events"
    end
  end

  WITH_FREQUENT = Class.new(Bali::Navigation::Base) do
    app_module :work, title: "Work", icon: "briefcase" do
      item :projects, title: "Projects", icon: "folder", path: "/projects", frequent: true
      item :calendar, title: "Calendar", path: "/calendar"
      item :drafts, title: "Drafts", path: "/drafts", frequent: true, gate: -> { false }
      item :archive, title: "Archive", path: -> { }, frequent: true
    end
    app_module :admin, title: "Administration", icon: "shield" do
      item :users, title: "Users", path: "/admin/users", frequent: true
    end
  end

  def groups
    page.all("[data-command-target='group']", visible: :all).map do |group|
      [ group.find(".cmd-group", visible: :all).text(:all).strip, group["data-mode"] ]
    end
  end

  def hrefs_by_group
    page.all("[data-command-target='group']", visible: :all).to_h do |group|
      [ group.find(".cmd-group", visible: :all).text(:all).strip,
        group.all("[data-command-target='row']", visible: :all).map { it["data-href"] } ]
    end
  end

  test "with modules: a group of modules on open, then the pages as you type" do
    render_inline(Bali::Command::Component.new(navigation: WITH_MODULES))

    assert_equal [ [ "Modules", "navigation" ], [ "Pages", "searchable" ] ], groups
    assert_selector "[data-mode='navigation'][data-href='/projects']", text: "Work", visible: :all
    assert_selector "[data-mode='navigation'][data-href='/admin']", text: "Administration", visible: :all
  end

  test "a module whose landing resolves to nil gets no row, and no landing means no Modules group" do
    navigation = Class.new(Bali::Navigation::Base) do
      app_module(:work, title: "Work") { item :projects, title: "Projects", path: "/projects" }
      app_module(:archive, title: "Archive") { item :old, title: "Old", path: -> { } }
    end
    render_inline(Bali::Command::Component.new(navigation: navigation))
    assert_selector "[data-mode='navigation'][data-href='/projects']", text: "Work", visible: :all
    assert_no_selector "[data-mode='navigation']", text: "Archive", visible: :all

    nowhere = Class.new(Bali::Navigation::Base) do
      app_module(:archive, title: "Archive") { item :old, title: "Old", path: -> { } }
    end
    render_inline(Bali::Command::Component.new(navigation: nowhere))
    assert_empty groups
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

  test "frequent pages: the palette opens on those this person may open, the rest wait for a query" do
    render_inline(Bali::Command::Component.new(navigation: WITH_FREQUENT))

    assert_equal [ [ "Frequent", "recent" ], [ "Modules", "searchable" ], [ "Pages", "searchable" ] ], groups
    assert_equal %w[/projects /admin/users], hrefs_by_group["Frequent"]
    assert_equal %w[/projects /calendar /admin/users], hrefs_by_group["Pages"]
    assert_selector "[data-mode='recent'][data-href='/admin/users']", text: "Administration", visible: :all
  end

  test "frequent pages without modules: the pages wait for a query too" do
    navigation = Class.new(Bali::Navigation::Base) do
      section :monitoring, title: "Monitoring" do
        item :events, title: "Events", path: "/events", frequent: true
        item :deliveries, title: "Deliveries", path: "/deliveries"
      end
    end
    render_inline(Bali::Command::Component.new(navigation: navigation))

    assert_equal [ [ "Frequent", "recent" ], [ "Pages", "searchable" ] ], groups
    assert_equal %w[/events], hrefs_by_group["Frequent"]
  end

  test "no frequent page this person may open: the palette opens as it did" do
    navigation = Class.new(Bali::Navigation::Base) do
      app_module :work, title: "Work" do
        item :projects, title: "Projects", path: "/projects"
        item :drafts, title: "Drafts", path: "/drafts", frequent: true, gate: -> { false }
        item :archive, title: "Archive", path: -> { }, frequent: true
      end
    end
    render_inline(Bali::Command::Component.new(navigation: navigation))

    assert_equal [ [ "Modules", "navigation" ], [ "Pages", "searchable" ] ], groups
  end

  test "the palette draws no group's badge and no item's link class" do
    navigation = Class.new(Bali::Navigation::Base) do
      section :data, title: "Data" do
        group :pending, title: "Pending", badge: -> { raise "the palette ran a group's badge" } do
          item :discrepancies, title: "Discrepancies", path: "/discrepancies", link_class: "line-through"
        end
      end
    end
    render_inline(Bali::Command::Component.new(navigation: navigation))

    assert_selector "[data-command-target='row'][data-href='/discrepancies']", visible: :all
    assert_no_selector ".line-through", visible: :all
  end

  test "the group names are Bali's translation" do
    I18n.with_locale(:es) { render_inline(Bali::Command::Component.new(navigation: WITH_FREQUENT)) }

    assert_equal %w[Frecuentes Módulos Páginas], groups.map(&:first)
  end
end
