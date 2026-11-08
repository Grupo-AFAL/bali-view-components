# frozen_string_literal: true

require "test_helper"

# The paths are afal-apps': its TDFlow portal and back-office share the `td_flow` namespace, and
# both claim `td_flow/initiatives` — the portal so a requester opening their initiative stays in it.
class NavigationLocateTest < ActiveSupport::TestCase
  NAVIGATION = Class.new(Bali::Navigation::Base) do
    app_module :tdflow_portal, title: "Portal", controllers: %w[td_flow/portal] do
      item :portal_proposals, path: "/portal/proposals", controllers: %w[td_flow/portal/proposals td_flow/initiatives]
      item :portal_value, path: "/portal/value", controllers: %w[td_flow/portal/value_showcase]
    end

    app_module :tdflow, title: "TDFlow", controllers: %w[td_flow] do
      item :tdflow_portfolio, path: "/initiatives", controllers: %w[td_flow/initiatives]
      group :tdflow_config, title: "Configuration" do
        item :tdflow_scoring, path: "/config?tab=scoring", controllers: %w[td_flow/scoring_configs]
        item :tdflow_salaries, path: "/config?tab=salaries", controllers: %w[td_flow/scoring_configs]
      end
    end

    app_module :administration, title: "Administration", controllers: %w[admin reports] do
      item :admin_users, path: "/admin/users", controllers: %w[admin/users]
      item :admin_reports, path: "/reports", controllers: %w[reports]
    end

    outside_menu "td_flow/mcp"
  end

  def locate(path) = NAVIGATION.locate(path)

  test "rule 1: the entry with the most segments wins" do
    location = locate("td_flow/portal/value_showcase")

    assert_equal :tdflow_portal, location.app_module.key
    assert_equal :portal_value, location.item.key
  end

  test "rule 1 places a controller only its module claims, without an item" do
    location = locate("td_flow/portal/unknown")

    assert_equal :tdflow_portal, location.app_module.key
    assert_nil location.item
    assert_nil location.section
  end

  test "rule 2: on a tie, the claim its ancestors support" do
    assert_equal :tdflow_portfolio, locate("td_flow/initiatives").item.key
  end

  test "rule 2 makes an item beat its own module on the same entry" do
    assert_equal :admin_reports, locate("reports/monthly").item&.key
  end

  test "rule 3: on a tie, the first declared" do
    location = locate("td_flow/scoring_configs")

    assert_equal :tdflow_scoring, location.item.key
    assert_equal :tdflow_config, location.item.parent.key
  end

  test "an entry claims below it at a slash, never a sibling sharing its prefix" do
    assert_equal :admin_users, locate("admin/users/deactivations").item.key
    assert_equal :administration, locate("admin").app_module.key
    assert_nil locate("administrations")
    assert_not NAVIGATION.claimed?("administrations")
  end

  test "an outside_menu entry places nothing, and still claims the path" do
    assert_nil locate("td_flow/mcp")
    assert NAVIGATION.claimed?("td_flow/mcp")
  end

  test "the location names the section an item sits in" do
    location = locate("admin/users")

    assert location.section.implicit?
    assert_equal "Administration", location.section.title
  end
end
