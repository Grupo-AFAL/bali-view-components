# frozen_string_literal: true

require "test_helper"

class BaliBpmnEditorDataTest < ActiveSupport::TestCase
  Data = Bali::BpmnEditor::Data

  def valid
    {
      "version" => 1, "orientation" => "vertical",
      "lanes" => [ { "id" => "l1", "name" => "Accounts", "kind" => "external", "size" => "180" } ],
      "nodes" => [ { "id" => "n1", "type" => "task", "lane_id" => "l1", "x" => 10, "y" => "20.5" } ],
      "edges" => [ { "id" => "e1", "source" => "n1", "target" => "n2", "type" => "message_flow",
                     "ports" => { "source" => "auto", "target" => "left" } } ],
      "issues" => [ { "rule" => "R11", "element_id" => "n1", "severity" => "warning" } ]
    }
  end

  def test_a_valid_document_is_symbolized_and_kept_whole
    data = Data.new(valid.merge("custom" => { "keep" => true }))

    assert_equal "vertical", data.orientation
    assert_equal({ keep: true }, data.to_h[:custom])
  end

  # The island lists dangling references as pending issues (R25, R26): an
  # imported document has to open to be fixed.
  def test_dangling_references_do_not_raise
    assert_nothing_raised { Data.new(valid) }
    assert_nothing_raised { Data.new(nodes: [ { id: "n1", type: "task", lane_id: "gone" } ]) }
  end

  def test_unknown_node_types_are_carried_through
    data = Data.new(nodes: [ { id: "n1", type: "transaction" } ])

    assert_equal "transaction", data.nodes.first[:type]
  end

  def test_structural_problems_raise
    {
      "not a hash" => "flow",
      "bad orientation" => { orientation: "diagonal" },
      "lane without id" => { lanes: [ { name: "x" } ] },
      "unknown lane kind" => { lanes: [ { id: "l1", kind: "partner" } ] },
      "node without type" => { nodes: [ { id: "n1" } ] },
      "duplicate node ids" => { nodes: [ { id: "n1", type: "task" }, { id: "n1", type: "task" } ] },
      "coordinate not a number" => { nodes: [ { id: "n1", type: "task", x: "left" } ] },
      "edge without target" => { edges: [ { id: "e1", source: "n1" } ] },
      "unknown edge type" => { edges: [ { id: "e1", source: "a", target: "b", type: "data_flow" } ] },
      "unknown port" => { edges: [ { id: "e1", source: "a", target: "b", ports: { source: "north" } } ] },
      "issue severity" => { issues: [ { rule: "R1", severity: "fatal" } ] },
      "collection not an array" => { nodes: { id: "n1" } },
      "version not an integer" => { version: "v2" },
      "pool not a hash" => { pool: "x" },
      "issue not a hash" => { issues: [ "oops" ] },
      "ports not a hash" => { edges: [ { id: "e1", source: "a", target: "b", ports: "auto" } ] },
      "annotation without id" => { annotations: [ { text: "x" } ] },
      "stencil without reference" => { stencil: [ { label: "x" } ] }
    }.each do |label, payload|
      assert_raises(Data::InvalidError, label) { Data.new(payload) }
    end
  end
end
