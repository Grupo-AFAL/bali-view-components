// Prints the BPMN XML export of the document read from stdin; used by
// test/bali/components/bpmn_editor/bpmn_xml_export_test.rb, which parses the
// output strictly — a check the JS tests cannot make without an XML parser.
import { normalize } from '../../../../app/components/bali/bpmn_editor/model/document.js'
import { toBpmnXml } from '../../../../app/components/bali/bpmn_editor/model/bpmnXml.js'

let input = ''
process.stdin.on('data', (chunk) => { input += chunk })
process.stdin.on('end', () => process.stdout.write(toBpmnXml(normalize(JSON.parse(input)), { name: 'Sample & <flow>' })))
