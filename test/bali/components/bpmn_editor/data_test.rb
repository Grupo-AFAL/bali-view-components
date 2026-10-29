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

  # An issue's element_id and an annotation's target_id do not say which
  # kind of element they name.
  def test_ids_are_unique_across_lanes_nodes_and_edges
    error = assert_raises(Data::InvalidError) do
      Data.new(lanes: [ { id: 5 } ], nodes: [ { id: "5", type: "task", lane_id: 5 } ], edges: [ { id: "e1", source: "5", target: "5" } ])
    end
    assert_includes error.message, %(["5"])
    assert_raises(Data::InvalidError) { Data.new(nodes: [ { id: "n1", type: "task" } ], edges: [ { id: "n1", source: "n1", target: "n1" } ]) }
    assert_nothing_raised { Data.new(lanes: [ { id: "lane_1" } ], nodes: [ { id: "n_1", type: "task" } ], edges: [ { id: "e_1", source: "n_1", target: "n_1" } ]) }
  end

  def with_url(url)
    {
      lanes: [ { id: "l1", assignee: { id: "p1", label: "Clerk", url: url } } ],
      nodes: [ { id: "n1", type: "sub_process", reference: { id: "77", label: "Payments", url: url } } ],
      stencil: [ { reference: { id: "78", label: "Hiring", url: url } } ]
    }
  end

  def test_a_url_is_a_path_or_http
    [ "/processes/7", "processes/7?tab=flow", "#n1", "//catalog.example/7", "https://catalog.example/7", "HTTP://x", "" ].each do |url|
      assert_equal url, Data.new(with_url(url)).nodes.first.dig(:reference, :url)
    end
    assert_nil Data.new(with_url(nil)).nodes.first.dig(:reference, :url)
  end

  # Followed on a click, a javascript: URL saved in the document would run
  # in the page of whoever opens it.
  def test_any_other_scheme_raises_wherever_the_url_is
    [ "javascript:alert(1)", " JavaScript:alert(1)", "java\tscript:alert(1)", "java\nscript:alert(1)", "\x01javascript:alert(1)",
      "data:text/html,<script>alert(1)</script>", "vbscript:x", 42 ].each do |url|
      %i[lanes nodes stencil].each do |key|
        payload = with_url(nil).merge(key => with_url(url)[key])
        error = assert_raises(Data::InvalidError, "#{key} #{url.inspect}") { Data.new(payload) }
        assert_includes error.message, "url must be a path or http/https"
      end
    end
  end

  def node_with(appearance)
    { nodes: [ { id: "n1", type: "sub_process", appearance: appearance } ] }
  end

  def test_an_appearance_is_accepted_and_kept
    data = Data.new(node_with(color: "#E9A23B", dimmed: true, badge: "En proceso"))

    assert_equal({ color: "#E9A23B", dimmed: true, badge: "En proceso" }, data.nodes.first[:appearance])
    assert_nothing_raised { Data.new(node_with(color: "#fff")) }
    assert_nothing_raised { Data.new(node_with(badge: "x" * Data::BADGE_MAX)) }
  end

  def test_an_appearance_that_cannot_be_drawn_raises
    {
      "must be a Hash" => "#E9A23B",
      "unknown keys" => { colour: "#E9A23B" },
      "hex colour" => { color: "orange" },
      "true or false" => { dimmed: "yes" },
      "at most 24 characters" => { badge: "x" * (Data::BADGE_MAX + 1) }
    }.each do |message, appearance|
      error = assert_raises(Data::InvalidError, message) { Data.new(node_with(appearance)) }

      assert_includes error.message, message
      assert_includes error.message, "node n1"
    end
    assert_raises(Data::InvalidError) { Data.new(node_with(badge: 12)) }
  end

  def sized(type, **size) = { nodes: [ { id: "n1", type: type, **size } ] }

  # «Auto» is a size left out, null or 0. The limits a person resizes within
  # are the island's: a document may draw an activity at any positive size.
  def test_a_positive_size_or_auto_is_kept
    assert_equal 240, Data.new(sized("task", width: 240, height: 90)).nodes.first[:width]
    assert_nothing_raised { Data.new(sized("sub_process", width: nil, height: nil)) }
    assert_nothing_raised { Data.new(sized("task", width: 0, height: "0")) }
    assert_nothing_raised { Data.new(sized("task", width: 28, height: "28")) }
    assert_nothing_raised { Data.new(sized("group", width: 1200, height: 600)) }
  end

  def test_a_negative_size_raises
    [ { width: -1 }, { height: "-5" } ].each do |size|
      error = assert_raises(Data::InvalidError, size.inspect) { Data.new(sized("exclusive_gateway", **size)) }

      assert_includes error.message, "must not be negative"
      assert_includes error.message, "node n1"
    end
  end

  def lane_with(appearance)
    { lanes: [ { id: "l1", name: "Treasury", appearance: appearance } ] }
  end

  def test_a_lane_takes_the_same_appearance_as_a_node
    data = Data.new(lane_with(color: "#DC2626", dimmed: true, badge: "Unassigned"))

    assert_equal({ color: "#DC2626", dimmed: true, badge: "Unassigned" }, data.lanes.first[:appearance])
    {
      "unknown keys" => { colour: "#DC2626" },
      "hex colour" => { color: "red" },
      "true or false" => { dimmed: 1 },
      "at most 24 characters" => { badge: "x" * (Data::BADGE_MAX + 1) }
    }.each do |message, appearance|
      error = assert_raises(Data::InvalidError, message) { Data.new(lane_with(appearance)) }

      assert_includes error.message, message
      assert_includes error.message, "lane l1"
    end
  end
end
