# frozen_string_literal: true

require "test_helper"
require "open3"

# The island's "Download .bpmn" (model/bpmnXml.js), run through node and parsed
# strictly here: well-formed XML, BPMN 2.0 semantics where the island maps
# them (external lanes as participants, message flows in the collaboration,
# sub-processes as call activities) and diagram interchange for every shape.
class BaliBpmnXmlExportTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("../javascript/bpmn_editor/bin/to_bpmn_xml.js")
  NS = { "bpmn" => "http://www.omg.org/spec/BPMN/20100524/MODEL",
         "bpmndi" => "http://www.omg.org/spec/BPMN/20100524/DI" }.freeze

  def export(document)
    output, status = Open3.capture2e("node", SCRIPT.to_s, stdin_data: document.to_json)
    assert status.success?, output
    Nokogiri::XML(output) { |config| config.strict }
  end

  def test_the_sample_flow_exports_as_valid_bpmn
    flow = BpmnSampleFlows.invoice
    flow[:nodes] << { id: "sp", type: "sub_process", lane_id: "l3", name: "Supplier onboarding",
                      reference: { id: "101", label: "Alta" }, x: 1200, y: 388 }
    flow[:nodes] << { id: "odd", type: "transaction", lane_id: "l3", name: "Unknown", x: 1400, y: 388 }
    xml = export(flow)

    assert_equal [ "Participant_main", "Participant_l1" ], xml.xpath("//bpmn:participant", NS).pluck("id")
    assert_equal "Sample & <flow>", xml.at_xpath("//bpmn:participant[@id='Participant_main']", NS)["name"]
    assert_equal 1, xml.xpath("//bpmn:collaboration/bpmn:messageFlow", NS).size
    assert_equal [ "Cuentas por pagar", "Tesorería" ], xml.xpath("//bpmn:lane", NS).pluck("name")
    # An xsd:QName: the numeric reference id gets the same "_" prefix as every id.
    assert_equal "_101", xml.at_xpath("//bpmn:callActivity", NS)["calledElement"]
    assert xml.at_xpath("//bpmn:task[@id='odd']//*[local-name()='element'][@type='transaction']", NS)
    assert xml.at_xpath("//bpmn:startEvent/bpmn:messageEventDefinition", NS)
    assert_equal "Sí", xml.at_xpath("//bpmn:sequenceFlow[@id='Flow_f3']", NS)["name"]

    shapes = xml.xpath("//bpmndi:BPMNShape", NS).pluck("bpmnElement")
    flow[:nodes].each { |node| assert_includes shapes, node[:id] }
    assert_operator xml.xpath("//bpmndi:BPMNEdge", NS).size, :>=, flow[:edges].size
  end

  # The contract keeps ids unique per kind only; the file has one namespace.
  # The Yes/No decision is an exclusive gateway with its X hidden (BPMN DI).
  def test_the_yes_no_decision_exports_with_its_marker_hidden
    flow = BpmnSampleFlows.invoice
    flow[:nodes] << { id: "yn", type: "exclusive_gateway", marker_visible: false, lane_id: "l2", name: "¿Completa?",
                      x: 700, y: 300 }
    xml = export(flow)

    assert_equal "false", xml.at_xpath("//bpmndi:BPMNShape[@bpmnElement='yn']", NS)["isMarkerVisible"]
    assert_equal "true", xml.at_xpath("//bpmndi:BPMNShape[@bpmnElement='g1']", NS)["isMarkerVisible"]
    assert xml.at_xpath("//bpmn:exclusiveGateway[@id='yn']", NS)
  end

  def test_ids_shared_across_kinds_stay_unique_and_artifacts_follow_flows
    xml = export(lanes: [ { id: "1", name: "A" }, { id: "2", name: "B" } ],
                 nodes: [ { id: "1", type: "task", lane_id: "1", name: "Do", x: 80, y: 40 },
                          { id: "2", type: "end_event", lane_id: "1", name: "Done", x: 300, y: 50 },
                          { id: "3", type: "text_annotation", name: "Why", x: 80, y: 120 },
                          { id: "4", type: "group", name: "Grouped", x: 60, y: 20 } ],
                 edges: [ { id: "1", source: "1", target: "2" }, { id: "2", type: "association", source: "3", target: "1" } ])

    ids = xml.xpath("//@id").map(&:value)
    assert_equal ids.uniq, ids, "duplicate ids in the export"
    process = xml.at_xpath("//bpmn:process[@id='Process_main']", NS).element_children.map(&:name)
    assert_operator process.index("sequenceFlow"), :<, process.index("textAnnotation")
    assert_nil xml.at_xpath("//bpmn:group", NS)["name"]
    assert_equal [ "_1", "_2" ], xml.xpath("//bpmn:lane[@id='Lane__1']/bpmn:flowNodeRef", NS).map(&:text)
  end

  def test_the_large_flow_exports
    xml = export(BpmnSampleFlows.large)

    assert_operator xml.xpath("//bpmn:task", NS).size, :>, 50
  end

  COLOR_NS = { "color" => "http://www.omg.org/spec/BPMN/non-normative/color/1.0",
               "bioc" => "http://bpmn.io/schema/bpmn/biocolor/1.0" }.freeze

  # BPMN in Color (OMG) and bpmn.io's pair, the attributes modelling tools read.
  def test_the_apps_colour_travels_as_bpmn_in_color_and_bpmn_io_attributes
    flow = BpmnSampleFlows.invoice
    flow[:nodes] = flow[:nodes].map do |n|
      case n[:id]
      when "t1" then n.merge(appearance: { color: "#E9A23B", badge: "En proceso", dimmed: true })
      when "t3" then n.merge(appearance: { color: "#fff" })
      when "t4" then n.merge(appearance: { badge: "Sin color" })
      else n
      end
    end
    xml = export(flow)
    raw = xml.to_xml

    shape = xml.at_xpath("//bpmndi:BPMNShape[@bpmnElement='t1']", NS)
    value = ->(element, name, prefix) { element.attribute_with_ns(name, COLOR_NS[prefix])&.value }
    assert_equal "#e9a23b", value.(shape, "border-color", "color")
    assert_equal "#fbf0e0", value.(shape, "background-color", "color"), "the tint the canvas paints"
    assert_equal "#e9a23b", value.(shape, "stroke", "bioc")
    assert_equal "#fbf0e0", value.(shape, "fill", "bioc")
    assert_equal "#ffffff", value.(xml.at_xpath("//bpmndi:BPMNShape[@bpmnElement='t3']", NS), "stroke", "bioc")
    assert_empty xml.at_xpath("//bpmndi:BPMNShape[@bpmnElement='t4']", NS).attributes.keys & %w[stroke fill border-color background-color]
    refute_includes raw, "En proceso", "the badge is not interchange"
    refute_includes raw, "dimmed"
  end

  def test_without_a_colour_the_export_declares_no_colour_namespace
    raw = export(BpmnSampleFlows.invoice).to_xml

    COLOR_NS.each_value { |uri| refute_includes raw, uri }
    refute_match(/bioc:|color:/, raw)
  end
end
