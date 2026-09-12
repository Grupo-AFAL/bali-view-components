# frozen_string_literal: true

require "test_helper"

# Validates the frozen Bali::Gantt contract against a REAL sample of
# TDFlow::GanttSerializer output (test/fixtures/gantt/td_flow_gantt_serializer.json,
# frozen from afal-apps 05/08/2026). `contract_from_serializer` below is the
# rename mapping afal-apps adopts in phase 4 (D19: renames live in the host's
# serializer, no aliases in the gem). If the contract cannot express something
# the island consumes today, this test is where it surfaces.
class BaliGanttSerializerContractTest < ActiveSupport::TestCase
  FIXTURE = Rails.root.join("../../test/fixtures/gantt/td_flow_gantt_serializer.json")

  def serializer_doc
    @serializer_doc ||= JSON.parse(File.read(FIXTURE))
  end

  # stage→group, task→item, title→name, *_id renames. is_critical and row_kind
  # are not mapped: the contract derives them (critical_ids / parent_id).
  def contract_from_serializer(doc)
    {
      window: doc["window"],
      groups: doc["stages"].map do |stage|
        { id: stage["id"], name: stage["name"], parent_id: stage["parent_stage_id"],
          position: stage["position"], status: stage["status"],
          starts_on: stage["starts_on"], ends_on: stage["ends_on"] }
      end,
      items: doc["tasks"].map do |task|
        { id: task["id"], group_id: task["stage_id"], parent_id: task["parent_task_id"],
          name: task["title"], starts_on: task["starts_on"], ends_on: task["ends_on"],
          status: task["status"], priority: task["priority"],
          percent_complete: task["percent_complete"], assignee: task["assignee"],
          slack_days: task["slack_days"] }
      end,
      dependencies: doc["dependencies"],
      critical_ids: doc["critical_task_ids"]
    }
  end

  def data
    @data ||= Bali::Gantt::Data.new(contract_from_serializer(serializer_doc))
  end

  def test_the_real_serializer_sample_maps_into_a_valid_document
    assert_predicate data, :any?
    assert_equal 3, data.dated_total
    assert_equal 1, data.undated_total
  end

  def test_window_survives_the_mapping
    assert_equal Date.new(2026, 5, 4), data.window_starts_on
    assert_equal Date.new(2026, 6, 5), data.window_ends_on
  end

  def test_nested_stages_keep_their_tree
    groups = data.ordered_groups

    assert_equal [ 11, 12, 13 ], groups.map(&:id)
    assert_equal 12, groups.last.parent_id
  end

  def test_subtasks_keep_their_row_kind_via_parent_id
    rows = data.items_for(11)

    assert_equal [ 101, 102 ], rows.map(&:id)
    assert rows.second.sub_item?, "row_kind: subtask must be derivable from parent_id"
    refute rows.first.sub_item?
  end

  def test_is_critical_is_fully_recoverable_from_critical_ids
    serializer_doc["tasks"].each do |task|
      assert_equal task["is_critical"], data.critical?(task["id"]),
                   "is_critical for task #{task['id']} lost in the mapping"
    end
  end

  def test_optional_fields_the_island_consumes_survive
    task = data.items_for(11).first

    assert_equal 100, task.percent_complete
    assert_equal 0, task.slack_days
    assert_equal "high", task.priority
    assert_equal "AD", task.assignee.initials

    dep = data.dependencies.first
    assert_equal [ "finish_to_start", 0 ], [ dep.dependency_type, dep.lag_days ]
  end

  def test_stage_own_dates_give_groups_their_bars
    design = data.ordered_groups.second

    assert_predicate design, :dated?
    assert_equal Date.new(2026, 5, 18), design.starts_on
  end
end
