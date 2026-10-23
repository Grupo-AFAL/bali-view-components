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
    tag = stream(bali_bpmn_lane_assignee_created(target: "flow_1_bpmn", client_lane_id: "l2",
                                                 assignee: { id: "role:1", label: "Buyer", group: "Role" }))

    assert_equal "lane-assignee-created", tag["event"]
    assert_equal "Role", JSON.parse(tag["detail"]).dig("assignee", "group")
    assert_equal "reload", stream(bali_bpmn_reload(target: "x"))["event"]
  end

  def test_the_app_opens_switches_and_closes_the_comparison
    assert_equal({ "index" => 1, "mode" => "overlay" }, JSON.parse(stream(bali_bpmn_event("compare", target: "x", index: 1, mode: "overlay"))["detail"]))
    assert_equal({ "mode" => nil }, JSON.parse(stream(bali_bpmn_event("compare", target: "x", mode: nil))["detail"]))
  end

  def test_unknown_events_and_incomplete_references_raise
    assert_raises(ArgumentError) { bali_bpmn_event("node-deleted", target: "x") }
    assert_raises(ArgumentError) { bali_bpmn_reference_created(client_node_id: "n1", reference: { label: "No id" }) }
  end

  # The island saves this URL into the document, and the host's next render
  # (Data#navigable_url!) would raise on it: the helper refuses it up front.
  def test_a_reference_or_assignee_url_that_is_not_a_path_or_http_raises
    [ "mailto:a@b.c", "javascript:alert(1)", "java\tscript:alert(1)", 42 ].each do |url|
      assert_raises(ArgumentError, url.inspect) do
        bali_bpmn_reference_created(target: "x", client_node_id: "n1", reference: { id: 1, label: "X", url: url })
      end
      assert_raises(ArgumentError, url.inspect) do
        bali_bpmn_lane_assignee_created(target: "x", client_lane_id: "l1", assignee: { id: 1, label: "X", url: url })
      end
    end
  end

  def test_what_the_helper_accepts_is_a_url_data_accepts
    [ "/p/1", "https://example.com/p/1", "p/1?tab=2" ].each do |url|
      detail = JSON.parse(stream(bali_bpmn_reference_created(target: "x", client_node_id: "n1",
                                                             reference: { id: 1, label: "X", url: url }))["detail"])
      payload = { nodes: [ { id: "n1", type: "sub_process", reference: detail["reference"] } ] }

      assert_nothing_raised { Bali::BpmnEditor::Data.new(payload) }
    end
  end

  # Two editors on a page can hold the same ids: an event that names no
  # editor would change whichever editor caught it.
  def test_every_event_names_its_editor
    assert_raises(ArgumentError) { bali_bpmn_reload(target: "") }
    assert_raises(ArgumentError) { bali_bpmn_event("reload", target: nil) }
    assert_raises(ArgumentError) { bali_bpmn_reference_created(client_node_id: "n1", reference: { id: 1, label: "x" }) }
  end

  # The island reads these names (streamAction.js STREAM_ACTION and the
  # `bali-bpmn:` listeners). Read with comments stripped: a name left in a
  # comment after its listener went away must not pass.
  def test_the_names_match_the_island
    island = Dir[Bali::Engine.root.join("app/components/bali/bpmn_editor/**/*.{js,jsx}")].map do |file|
      File.read(file).gsub(%r{/\*.*?\*/}m, "").gsub(%r{^\s*//.*$}, "").gsub(%r{\s//\s.*$}, "")
    end.join("\n")

    assert_match(/STREAM_ACTION = 'bali_bpmn_event'/, island)
    Bali::BpmnEditorHelper::EVENTS.each { |event| assert_includes island, "'bali-bpmn:#{event}'" }
  end
end
