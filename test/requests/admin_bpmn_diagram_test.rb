# frozen_string_literal: true

require "test_helper"

# The dummy's reference implementation of the Bali::BpmnEditor save contract
# (docs/api/bpmn-editor.md): what a host copies, so it has to answer exactly
# what the island expects.
class AdminBpmnDiagramTest < ActionDispatch::IntegrationTest
  setup do
    @flow = ProcessFlow.create!(name: "Supplier payments",
                                document: BpmnSampleFlows.invoice.except(:version, :status_label))
  end

  def diagram_path = "/admin/process_flows/#{@flow.id}/diagram"
  def finalization_path = "/admin/process_flows/#{@flow.id}/finalization"

  def document_with(name)
    doc = @flow.to_diagram.except(:issues, :status_label)
    doc[:nodes] = doc[:nodes].map { |n| n[:id] == "t1" ? n.merge(name: name) : n }
    doc
  end

  def test_get_answers_the_complete_document
    get diagram_path, as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 1, body["version"]
    assert_equal 9, body["nodes"].size
    assert body.key?("issues")
  end

  def test_put_with_the_current_version_saves_and_answers_the_next_version
    put diagram_path, params: { diagram: document_with("Check invoice"), version: 1 }, as: :json

    assert_response :ok
    assert_equal 2, response.parsed_body["version"]
    assert_equal "Check invoice", @flow.reload.document["nodes"].find { |n| n["id"] == "t1" }["name"]
  end

  def test_put_with_a_stale_version_is_a_conflict
    put diagram_path, params: { diagram: document_with("First"), version: 1 }, as: :json
    put diagram_path, params: { diagram: document_with("Second"), version: 1 }, as: :json

    assert_response :conflict
    assert_equal "First", @flow.reload.document["nodes"].find { |n| n["id"] == "t1" }["name"]
  end

  def test_put_with_a_malformed_document_is_unprocessable
    put diagram_path, params: { diagram: { nodes: [ { id: "n1" } ] }, version: 1 }, as: :json

    assert_response :unprocessable_entity
    assert_match(/requires a type/, response.parsed_body["errors"].first)
  end

  def test_finalize_refuses_while_a_server_rule_raises_an_error
    doc = document_with("Validate invoice")
    doc[:nodes] << { id: "sp", type: "sub_process", lane_id: "l2", name: "Gone",
                     reference: { id: "999", label: "Removed" }, x: 700, y: 300 }

    post finalization_path, params: { diagram: doc, version: 1 }, as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["issues"].pluck("rule"), "APP02"
    assert_equal 2, response.parsed_body["version"], "the draft was saved; the next PUT needs this version"
    assert_nil @flow.reload.finalized_at
  end

  def test_finalize_marks_the_flow_finalized
    post finalization_path, params: { diagram: document_with("Validate invoice"), version: 1 }, as: :json

    assert_response :ok
    assert_match(/Finalizado/, response.parsed_body["status_label"])
    assert @flow.reload.finalized_at
  end
end

class AdminBpmnReferencesTest < ActionDispatch::IntegrationTest
  setup do
    @flow = ProcessFlow.create!(name: "Supplier payments", document: BpmnSampleFlows.invoice.except(:version))
  end

  def test_the_search_answers_items_with_their_group
    get "/admin/process_flows/#{@flow.id}/references", params: { q: "alta" }, as: :json

    assert_equal [ "Alta de proveedor" ], response.parsed_body.pluck("label")
    assert_equal "Compras", response.parsed_body.first["group"]
  end

  def test_the_lane_assignee_search_narrows_by_group
    get "/admin/process_flows/#{@flow.id}/lane_assignees", params: { group: "Rol" }, as: :json

    assert(response.parsed_body.all? { |item| item["group"] == "Rol" })
  end

  def test_creating_a_reference_answers_the_stream_that_links_the_node
    post "/admin/process_flows/#{@flow.id}/references",
         params: { reference: { label: "Supplier review", group: "Compras" }, client_node_id: "n9", editor_id: "flow_bpmn" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
    stream = Nokogiri::HTML.fragment(response.body).at("turbo-stream[action='bali_bpmn_event']")
    assert_equal "flow_bpmn", stream["target"]
    detail = JSON.parse(stream["detail"])
    assert_equal "n9", detail["client_node_id"]
    assert_equal "Supplier review", detail.dig("reference", "label")
  end

  def test_the_document_proposes_what_is_still_to_place
    get "/admin/process_flows/#{@flow.id}/diagram", as: :json

    labels = response.parsed_body["stencil"].map { |item| item.dig("reference", "label") }
    assert_includes labels, "Conciliación bancaria"
  end
end
