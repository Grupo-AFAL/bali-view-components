# frozen_string_literal: true

require "test_helper"

class BaliGanttDataTest < ActiveSupport::TestCase
  def base_payload
    {
      groups: [
        { id: 1, name: "Discovery" },
        { id: 2, name: "Design" },
        { id: 3, name: "Technical design", parent_id: 2 }
      ],
      items: [
        { id: 10, group_id: 1, name: "Interviews", starts_on: "2026-01-05", ends_on: "2026-01-16" },
        { id: 11, group_id: 1, name: "Summary", parent_id: 10, starts_on: "2026-01-12", ends_on: "2026-01-16" },
        { id: 12, group_id: 2, name: "Wireframes", starts_on: "2026-01-19", ends_on: "2026-02-06" },
        { id: 13, group_id: 3, name: "Schema", starts_on: nil, ends_on: nil }
      ],
      dependencies: [
        { id: 1, predecessor_id: 10, successor_id: 12, dependency_type: "finish_to_start", lag_days: 2 }
      ],
      critical_ids: [ 10, 12 ]
    }
  end

  def data(payload = base_payload)
    Bali::Gantt::Data.new(payload)
  end

  def test_rejects_non_hash_payloads
    error = assert_raises(Bali::Gantt::Data::InvalidError) { data([]) }
    assert_match(/must be a Hash/, error.message)
  end

  def test_accepts_string_keys
    parsed = data(base_payload.deep_stringify_keys)

    assert_equal %w[Discovery Design], parsed.ordered_groups.reject(&:parent_id).map(&:name)
    assert_equal Date.new(2026, 1, 5), parsed.window_starts_on
  end

  def test_orders_sub_groups_after_their_parent
    assert_equal [ 1, 2, 3 ], data.ordered_groups.map(&:id)
  end

  def test_nests_sub_items_after_their_parent
    assert_equal [ 10, 11 ], data.items_for(1).map(&:id)
  end

  def test_derives_window_from_items_and_groups_when_absent
    parsed = data

    assert_equal Date.new(2026, 1, 5), parsed.window_starts_on
    assert_equal Date.new(2026, 2, 6), parsed.window_ends_on
  end

  def test_explicit_window_wins
    parsed = data(base_payload.merge(window: { starts_on: "2026-01-01", ends_on: "2026-03-31" }))

    assert_equal Date.new(2026, 1, 1), parsed.window_starts_on
    assert_equal Date.new(2026, 3, 31), parsed.window_ends_on
  end

  def test_group_own_dates_extend_the_derived_window
    payload = base_payload
    payload[:groups][1][:starts_on] = "2025-12-01"
    payload[:groups][1][:ends_on] = "2026-02-20"

    parsed = data(payload)

    assert_equal Date.new(2025, 12, 1), parsed.window_starts_on
    assert_equal Date.new(2026, 2, 20), parsed.window_ends_on
  end

  def test_single_date_items_stay_on_the_axis_as_minimal_ranges
    payload = base_payload
    payload[:items] << { id: 14, group_id: 2, name: "Only start", starts_on: "2026-01-20" }
    payload[:items] << { id: 15, group_id: 2, name: "Only end", ends_on: "2026-01-22" }

    parsed = data(payload)
    only_start = parsed.dated_items.find { |i| i.id == 14 }
    only_end = parsed.dated_items.find { |i| i.id == 15 }

    assert_equal [ Date.new(2026, 1, 20) ] * 2, [ only_start.starts_on, only_start.ends_on ]
    assert_equal [ Date.new(2026, 1, 22) ] * 2, [ only_end.starts_on, only_end.ends_on ]
  end

  def test_inverted_ranges_clamp_to_their_start
    payload = base_payload
    payload[:items] << { id: 14, group_id: 2, name: "Inverted", starts_on: "2026-01-20", ends_on: "2026-01-10" }

    item = data(payload).dated_items.find { |i| i.id == 14 }

    assert_equal item.starts_on, item.ends_on
  end

  def test_undated_items_are_split_out
    parsed = data

    assert_equal [ 13 ], parsed.undated_items.map(&:id)
    assert_equal 3, parsed.dated_total
    assert_equal 1, parsed.undated_total
  end

  # #970 removed `limit:` with the static board it capped. The island renders
  # the whole schedule, so the document that reaches it is the one handed in.
  def test_the_document_is_never_capped
    assert_raises(ArgumentError) { Bali::Gantt::Data.new(base_payload, limit: 2) }
    assert_equal [ 10, 11, 12 ], data.dated_items.map(&:id)
    assert_equal base_payload[:items].size, data.to_h.fetch(:items).size
  end

  def test_milestone_and_optional_fields_parse
    payload = base_payload
    payload[:items] << {
      id: 20, group_id: 2, name: "Release", starts_on: "2026-02-06", milestone: true,
      percent_complete: "150", slack_days: 4,
      assignee: { id: 7, name: "Ana Luz", initials: "AL" }, href: "/tasks/20"
    }

    item = data(payload).dated_items.find { |i| i.id == 20 }

    assert_predicate item, :milestone?
    assert_equal 100, item.percent_complete # clamped
    assert_equal 4, item.slack_days
    assert_equal "AL", item.assignee.initials
    assert_equal "/tasks/20", item.href
  end

  def test_critical_lookup
    parsed = data

    assert parsed.critical?(10)
    assert parsed.critical?(parsed.dated_items.find { |i| i.id == 12 })
    refute parsed.critical?(11)
  end

  def test_dependencies_parse_with_defaults
    dep = data.dependencies.first

    assert_equal [ 10, 12 ], [ dep.predecessor_id, dep.successor_id ]
    assert_equal "finish_to_start", dep.dependency_type
    assert_equal 2, dep.lag_days
  end

  def test_rejects_bad_iso_dates
    payload = base_payload
    payload[:items][0][:starts_on] = "05/01/2026"

    assert_raises(Bali::Gantt::Data::InvalidError) { data(payload) }
  end

  def test_rejects_unknown_group_references
    payload = base_payload
    payload[:items][0][:group_id] = 99

    assert_raises(Bali::Gantt::Data::InvalidError) { data(payload) }
  end

  def test_rejects_groups_nested_beyond_two_levels
    payload = base_payload
    payload[:groups] << { id: 4, name: "Too deep", parent_id: 3 }

    assert_raises(Bali::Gantt::Data::InvalidError) { data(payload) }
  end

  def test_rejects_items_nested_beyond_two_levels
    payload = base_payload
    payload[:items] << { id: 14, group_id: 1, name: "Too deep", parent_id: 11 }

    assert_raises(Bali::Gantt::Data::InvalidError) { data(payload) }
  end

  def test_rejects_sub_items_outside_their_parents_group
    payload = base_payload
    payload[:items][1][:group_id] = 2

    assert_raises(Bali::Gantt::Data::InvalidError) { data(payload) }
  end

  def test_rejects_items_without_id_or_name
    payload = base_payload
    payload[:items] << { group_id: 1, name: "No id" }

    assert_raises(Bali::Gantt::Data::InvalidError) { data(payload) }
  end

  def test_ungrouped_items_form_an_implicit_section
    payload = base_payload
    payload[:items] << { id: 30, name: "Loose end", starts_on: "2026-01-07", ends_on: "2026-01-09" }

    assert_equal [ 30 ], data(payload).ungrouped_items.map(&:id)
  end
end
