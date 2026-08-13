# frozen_string_literal: true

require "test_helper"

# The default status vocabulary is the last piece of colour the SERVER decides
# (#970 moved the rest into the island, which computes every bar from the
# `catalogs` prop). It is still a frontier: a host that configures no catalog
# gets Bali's defaults from Ruby, and the island's own defaults from JS, and the
# two have to name the same daisyUI variable for the same status.
#
# So this reads ganttColors.js instead of restating it — a one-character edit on
# either side used to be invisible until someone compared two screenshots.
class BaliGanttColorsTest < ActiveSupport::TestCase
  def island_status_vars
    source = Bali::Engine.root.join("app/components/bali/gantt/ganttColors.js").read
    statuses = source[/statuses:\s*\[(.*?)\]/m, 1]
    refute_nil statuses, "ganttColors.js no longer declares defaultCatalogs.statuses"

    statuses.scan(/value:\s*'(\w+)'.*?color:\s*(null|'([^']+)')/m)
            .to_h { |value, raw, var| [ value, raw == "null" ? nil : var ] }
  end

  def test_default_status_vars_match_the_island_defaults
    assert_equal island_status_vars, Bali::Gantt::Colors::DEFAULT_STATUS_VARS.to_h,
                 "Bali::Gantt::Colors and ganttColors.js disagree about the default status colours"
  end

  # The component turns this map into the `statuses` catalog a host inherits, so
  # order and nil-means-neutral are part of the contract, not incidental.
  def test_the_default_catalog_keeps_the_map_order_and_neutral_entries
    catalog = Bali::Gantt::Component.new(data: { items: [] }).statuses

    assert_equal Bali::Gantt::Colors::DEFAULT_STATUS_VARS.keys, catalog.map { |s| s[:value] }
    assert_nil catalog.first[:color]
    assert_equal "Backlog", catalog.first[:label]
    assert_equal "--color-info", catalog.second[:color]
  end
end
