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
    assert_equal "101", xml.at_xpath("//bpmn:callActivity", NS)["calledElement"]
    assert xml.at_xpath("//bpmn:task[@id='odd']//*[local-name()='element'][@type='transaction']", NS)
    assert xml.at_xpath("//bpmn:startEvent/bpmn:messageEventDefinition", NS)
    assert_equal "Sí", xml.at_xpath("//bpmn:sequenceFlow[@id='f3']", NS)["name"]

    shapes = xml.xpath("//bpmndi:BPMNShape", NS).pluck("bpmnElement")
    flow[:nodes].each { |node| assert_includes shapes, node[:id] }
    assert_operator xml.xpath("//bpmndi:BPMNEdge", NS).size, :>=, flow[:edges].size
  end

  def test_the_large_flow_exports
    xml = export(BpmnSampleFlows.large)

    assert_operator xml.xpath("//bpmn:task", NS).size, :>, 50
  end
end
