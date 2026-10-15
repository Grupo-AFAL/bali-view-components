# frozen_string_literal: true

require "test_helper"

class BaliBpmnEditorHelperTest < ActionView::TestCase
  include Bali::BpmnEditorHelper

  def stream(html)
    Nokogiri::HTML.fragment(html).at("turbo-stream")
  end

  def test_reference_created_renders_the_stream_action_the_island_installs
    tag = stream(bali_bpmn_reference_created(target: "flow_1_bpmn", client_node_id: "n9",
                                             reference: { id: 77, label: "Supplier onboarding", url: "/p/77" }))

    assert_equal "bali_bpmn_event", tag["action"]
    assert_equal "flow_1_bpmn", tag["target"]
    assert_equal "reference-created", tag["event"]
    assert_equal({ "client_node_id" => "n9", "reference" => { "id" => "77", "label" => "Supplier onboarding", "url" => "/p/77" } },
                 JSON.parse(tag["detail"]))
  end

  def test_lane_assignee_created_and_reload
    tag = stream(bali_bpmn_lane_assignee_created(client_lane_id: "l2", assignee: { id: "role:1", label: "Buyer", group: "Role" }))

    assert_nil tag["target"], "without a target the event goes to document"
    assert_equal "lane-assignee-created", tag["event"]
    assert_equal "Role", JSON.parse(tag["detail"]).dig("assignee", "group")
    assert_equal "reload", stream(bali_bpmn_reload(target: "x"))["event"]
  end

  def test_unknown_events_and_incomplete_references_raise
    assert_raises(ArgumentError) { bali_bpmn_event("node-deleted") }
    assert_raises(ArgumentError) { bali_bpmn_reference_created(client_node_id: "n1", reference: { label: "No id" }) }
  end

  # The island reads these names (streamAction.js STREAM_ACTION and the
  # `bali-bpmn:` listeners in BpmnEditor.jsx).
  def test_the_names_match_the_island
    stream_js = Rails.root.join("../../app/components/bali/bpmn_editor/streamAction.js").read
    editor_js = Rails.root.join("../../app/components/bali/bpmn_editor/BpmnEditor.jsx").read

    assert_includes stream_js, "STREAM_ACTION = 'bali_bpmn_event'"
    Bali::BpmnEditorHelper::EVENTS.each { |event| assert_includes editor_js, "'bali-bpmn:#{event}'" }
  end
end
