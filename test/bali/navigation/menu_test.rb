# frozen_string_literal: true

require "test_helper"

class NavigationMenuTest < ActiveSupport::TestCase
  # What a view offers the gates and paths, and a record of which gates ran.
  class Context
    attr_reader :controller_path, :calls

    def initialize(controller_path: "dashboard", query: {}, allowed: [])
      @controller_path = controller_path
      @query = query
      @allowed = allowed
      @calls = []
    end

    def can?(key)
      calls << key
      @allowed.include?(key)
    end

    def request
      ActionDispatch::TestRequest.create("QUERY_STRING" => @query.to_query)
    end

    def main_app
      Rails.application.routes.url_helpers
    end
  end

  NAVIGATION = Class.new(Bali::Navigation::Base) do
    authorize { |key| can?(key) }

    app_module :tdflow_portal, title: "Portal", icon: "lightbulb", controllers: %w[td_flow/portal] do
      item :portal_proposals, title: "My proposals", path: "/portal/proposals",
                              controllers: %w[td_flow/portal/proposals td_flow/initiatives]
      item :portal_faq, title: "FAQ", path: "/portal/faq", gate: "portal.faq"
    end

    app_module :tdflow, title: "TDFlow", icon: "folder-kanban", gate: "tdflow.back_office", controllers: %w[td_flow] do
      item :tdflow_portfolio, title: "Portfolio", path: -> { "/initiatives?by=#{controller_path}" },
                              controllers: %w[td_flow/initiatives], badge: -> { calls.push("badge").size }
      group :tdflow_config, title: "Configuration", icon: "sliders" do
        item :tdflow_scoring, title: "Scoring", path: "/config?tab=scoring", controllers: %w[td_flow/scoring_configs]
        item :tdflow_salaries, title: "Salaries", path: "/config?tab=salaries&view=bands",
                               controllers: %w[td_flow/scoring_configs]
      end
      item :tdflow_schedules, title: "Schedules", path: "/schedules", menu: false, keywords: %w[cadences],
                              controllers: %w[td_flow/report_schedules]
    end

    app_module :marketing, title: "Marketing", controllers: %w[marketing] do
      section :catalog, title: "Catalog" do
        item :marketing_cedis, title: "CEDIS catalog", path: "https://apex.example", target: "_blank",
                               hint: "Oracle APEX"
        item :marketing_dashboard, title: "Dashboard", path: :root_path, controllers: %w[marketing/dashboards]
      end
    end

    app_module :extras, title: "Extras", controllers: %w[extras] do
      item :extras_home, title: "Home", path: "/extras/home", gate: "extras.home"
      item :extras_only_in_palette, title: "Only in palette", path: "/extras", menu: false
    end
  end

  def menu(**)
    NAVIGATION.menu(Context.new(**))
  end

  test "a module shows when something drawn in it shows, after its own gate" do
    assert_equal %i[tdflow_portal marketing], menu.app_modules.map(&:key)
    assert_equal %i[tdflow_portal tdflow marketing], menu(allowed: %w[tdflow.back_office]).app_modules.map(&:key)
  end

  test "an item behind a closed gate is not offered, and its section stays while another item shows" do
    menu = menu()
    portal = NAVIGATION.find(:tdflow_portal)

    assert_equal %i[portal_proposals], menu.items(portal.children.first).map(&:key)
    assert_nil menu.find(:portal_faq)
  end

  test "a module whose only visible items are menu: false is not offered, nor are its items" do
    menu = menu()

    assert_not_includes menu.app_modules.map(&:key), :extras
    assert_nil menu.find(:extras_only_in_palette)
    assert_not_includes menu.palette_entries.pluck(:title), "Only in palette"
  end

  test "the three forms of a path" do
    menu = menu(controller_path: "td_flow/portal", allowed: %w[tdflow.back_office])

    assert_equal "/portal/proposals", menu.path(NAVIGATION.find(:portal_proposals))
    assert_equal "/", menu.path(NAVIGATION.find(:marketing_dashboard))
    assert_equal "/initiatives?by=td_flow/portal", menu.path(NAVIGATION.find(:tdflow_portfolio))
  end

  test "a module lands on its first item drawn in the side menu that opens in place, or on its landing" do
    nav = Class.new(Bali::Navigation::Base) do
      authorize { |key| can?(key) }
      app_module :reports, title: "Reports" do
        item :hidden, title: "Hidden", path: "/hidden", gate: "no"
        item :palette_only, title: "Palette", path: "/palette", menu: false
        item :elsewhere, title: "Elsewhere", path: "https://example.com", target: "_blank"
        group :charts, title: "Charts" do
          item :first, title: "First", path: "/charts/first"
        end
      end
      app_module :home, title: "Home", landing: "/welcome" do
        item :inbox, title: "Inbox", path: "/inbox"
      end
    end
    menu = nav.menu(Context.new)

    assert_equal "/charts/first", menu.landing(nav.find(:reports))
    assert_equal "/welcome", menu.landing(nav.find(:home))
  end

  LITERALS = Class.new(Bali::Navigation::Base) do
    app_module :reports, title: "Reports" do
      item :pending, title: "Pending", path: -> { }, badge: 3
      item :done, title: "Done", path: "/done", badge: "New"
    end
  end

  test "a literal badge is drawn as written" do
    menu = LITERALS.menu(Context.new)

    assert_equal [ 3, "New" ], [ menu.badge(LITERALS.find(:pending)), menu.badge(LITERALS.find(:done)) ]
  end

  test "a module lands past an item whose path resolves to nil" do
    assert_equal "/done", LITERALS.menu(Context.new).landing(LITERALS.find(:reports))
  end

  test "the location only counts what this person may open" do
    assert_equal :portal_proposals, menu(controller_path: "td_flow/initiatives").location.item.key
    assert_equal :tdflow_portfolio,
                 menu(controller_path: "td_flow/initiatives", allowed: %w[tdflow.back_office]).location.item.key
  end

  test "without a location, the current module is the first one offered" do
    menu = menu(controller_path: "users/sessions")

    assert_nil menu.location
    assert_equal :tdflow_portal, menu.current_app_module.key
  end

  test "items sharing a controller: without a query the first declared wins" do
    menu = menu(controller_path: "td_flow/scoring_configs", allowed: %w[tdflow.back_office])

    assert_equal :tdflow_scoring, menu.location.item.key
  end

  test "items sharing a controller: the one whose query the request carries wins" do
    menu = menu(controller_path: "td_flow/scoring_configs", query: { tab: "salaries", view: "bands" },
                allowed: %w[tdflow.back_office])

    assert_equal :tdflow_salaries, menu.location.item.key
  end

  test "items sharing a controller: the one matching more parameters wins" do
    nav = Class.new(Bali::Navigation::Base) do
      section :my_space, title: "My space" do
        item :inbox, title: "Inbox", path: "/inbox", controllers: %w[inbox]
        item :notices, title: "Notices", path: "/inbox?tab=notices", controllers: %w[inbox]
      end
    end

    assert_equal :inbox, nav.menu(Context.new(controller_path: "inbox")).location.item.key
    assert_equal :notices,
                 nav.menu(Context.new(controller_path: "inbox", query: { tab: "notices" })).location.item.key
  end

  test "items sharing a controller: when no query matches the first declared wins" do
    menu = menu(controller_path: "td_flow/scoring_configs", query: { tab: "budgets" }, allowed: %w[tdflow.back_office])

    assert_equal :tdflow_scoring, menu.location.item.key
  end

  test "current_controller_path decides what the request counts as" do
    nav = Class.new(Bali::Navigation::Base) do
      current_controller_path { controller_path == "versions" ? "processes" : controller_path }
      section :work, title: "Work" do
        item :processes, title: "Processes", path: "/processes", controllers: %w[processes]
      end
    end

    assert_equal :processes, nav.menu(Context.new(controller_path: "versions")).location.item.key
  end

  test "active is true for the placed item, false for the others, nil when no drawn item is placed" do
    menu = menu(controller_path: "td_flow/initiatives", allowed: %w[tdflow.back_office])

    assert menu.active(NAVIGATION.find(:tdflow_portfolio))
    assert_equal false, menu.active(NAVIGATION.find(:tdflow_scoring))
    assert_nil menu(controller_path: "td_flow/portal/unknown").active(NAVIGATION.find(:portal_proposals))
    assert_nil menu(controller_path: "td_flow/report_schedules", allowed: %w[tdflow.back_office])
                 .active(NAVIGATION.find(:tdflow_portfolio))
  end

  test "the palette offers what this person may open, in place, with what to search by" do
    entries = menu(allowed: %w[tdflow.back_office]).palette_entries.index_by { it[:title] }

    assert_equal [ "My proposals", "Portfolio", "Scoring", "Salaries", "Schedules", "Dashboard" ], entries.keys
    assert_equal "TDFlow", entries["Scoring"][:meta]
    assert_equal "Scoring Configuration TDFlow", entries["Scoring"][:search]
    assert_equal "Schedules TDFlow cadences", entries["Schedules"][:search]
    assert_equal "/config?tab=scoring", entries["Scoring"][:href]
  end

  test "an item without a path is left out of the palette" do
    nav = Class.new(Bali::Navigation::Base) do
      section :people, title: "People" do
        item :guests, title: "Guests", path: "/guests"
        item :pasaporte, title: "Pasaporte", path: -> { nil }
      end
    end

    assert_equal [ "Guests" ], nav.menu(Context.new).palette_entries.pluck(:title)
  end

  test "building the menu runs no badge" do
    context = Context.new(allowed: %w[tdflow.back_office])
    menu = NAVIGATION.menu(context)
    menu.app_modules
    menu.palette_entries

    assert_not_includes context.calls, "badge"

    badge = menu.badge(NAVIGATION.find(:tdflow_portfolio))
    assert_equal context.calls.size, badge
    assert_equal "badge", context.calls.last
  end

  test "each gate runs once per menu" do
    context = Context.new(controller_path: "td_flow/initiatives", allowed: %w[tdflow.back_office portal.faq])
    menu = NAVIGATION.menu(context)
    menu.app_modules
    menu.sections
    menu.location
    menu.palette_entries

    assert_equal context.calls.uniq, context.calls
  end

  test "the switcher and its landings stop at a module's first visible item" do
    context = Context.new
    menu = NAVIGATION.menu(context)
    menu.app_modules.each { menu.landing(it) }

    assert_not_includes context.calls, "portal.faq"
  end

  test "a menu for visibility needs no view" do
    viewer = Struct.new(:allowed) do
      def can?(key) = allowed.include?(key)
    end

    assert_equal %i[tdflow_portal tdflow marketing],
                 NAVIGATION.menu(viewer.new(%w[tdflow.back_office])).app_modules.map(&:key)
  end
end
