# frozen_string_literal: true

require "test_helper"

class BpmnEditorPreviewsTest < ActionDispatch::IntegrationTest
  %w[default vertical large empty review].each do |preview|
    define_method("test_the_#{preview}_preview_renders_the_island_and_its_loader_metas") do
      get "/lookbook/preview/bali/bpmn_editor/#{preview}"

      assert_response :ok
      assert_select "[data-controller='bpmn-editor'][data-bpmn-editor-data-value]", { minimum: 1 }
      assert_select "meta[name='bali-bpmn-editor-js']", { minimum: 1 }
    end
  end

  def test_the_editable_preview_starts_from_the_clean_sample_and_wires_the_dummy_endpoints
    ProcessFlow.create!(name: ProcessFlow::SAMPLE_NAME, document: { lanes: [ { id: "x", name: "Leftover" } ] }, version: 14)

    get "/lookbook/preview/bali/bpmn_editor/editable"

    assert_response :ok
    flow = ProcessFlow.find_by!(name: ProcessFlow::SAMPLE_NAME)
    assert_equal 1, flow.version
    assert_not_includes flow.document["lanes"].pluck("name"), "Leftover"
    island = css_select("[data-controller='bpmn-editor']").first
    assert_equal "true", island["data-bpmn-editor-editable-value"]
    assert_equal "/admin/process_flows/#{flow.id}/diagram", JSON.parse(island["data-bpmn-editor-urls-value"])["save"]
  end

  def test_the_configured_preview_hands_over_palette_notes_and_legend
    ProcessFlow.create!(name: "Preview flow", document: BpmnSampleFlows.invoice.except(:version))

    get "/lookbook/preview/bali/bpmn_editor/configured"

    island = css_select("[data-controller='bpmn-editor']").first
    palette = JSON.parse(island["data-bpmn-editor-palette-value"])
    assert_equal "disabled", palette["items"].find { |i| i["key"] == "complex_gateway" }["state"]
    assert_equal "Por confirmar con el área", palette["items"].find { |i| i["key"] == "signal_event" }["note"]
    assert_includes JSON.parse(island["data-bpmn-editor-legend-value"]).pluck("key"), "rework"
  end

  def test_the_large_preview_carries_more_than_fifty_activities
    get "/lookbook/preview/bali/bpmn_editor/large"

    document = JSON.parse(css_select("[data-bpmn-editor-data-value]").first["data-bpmn-editor-data-value"])
    assert_operator document.fetch("nodes").count { |n| n["type"] == "task" }, :>, 50
  end
end
