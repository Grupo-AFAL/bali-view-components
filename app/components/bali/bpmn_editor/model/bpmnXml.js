// The document as BPMN 2.0 XML with diagram interchange (DI), for the
// "Download .bpmn" button. Importing stays with the host (its drawer at
// `urls.import`), which owns what an import means for its records.
//
// Internal lanes form one process with a lane set; each EXTERNAL lane is a
// participant of its own, because BPMN only allows message flows between
// participants (§9.3). A sub-process with a reference exports as a call
// activity. Node types BPMN does not have travel in a `bali:element`
// extension on a plain task, so nothing is lost on the way out.
import { layoutLanes, laneRect, nodeBox, poolOrigin } from './geometry.js'
import { routeAll } from './routing.js'
import { edgeType, isFlowNode } from './catalog.js'

const TAGS = {
  task: 'task',
  user_task: 'userTask',
  service_task: 'serviceTask',
  send_task: 'sendTask',
  receive_task: 'receiveTask',
  script_task: 'scriptTask',
  business_rule_task: 'businessRuleTask',
  manual_task: 'manualTask',
  sub_process: 'callActivity',
  exclusive_gateway: 'exclusiveGateway',
  parallel_gateway: 'parallelGateway',
  inclusive_gateway: 'inclusiveGateway',
  complex_gateway: 'complexGateway',
  event_based_gateway: 'eventBasedGateway',
  start_event: 'startEvent',
  intermediate_catch_event: 'intermediateCatchEvent',
  intermediate_throw_event: 'intermediateThrowEvent',
  end_event: 'endEvent',
  text_annotation: 'textAnnotation',
  group: 'group',
  data_object: 'dataObjectReference',
  data_collection: 'dataObjectReference',
  data_input: 'dataObjectReference',
  data_output: 'dataObjectReference',
  data_store: 'dataStoreReference'
}

const DEFINITIONS = {
  timer: 'timerEventDefinition',
  message: 'messageEventDefinition',
  conditional: 'conditionalEventDefinition',
  signal: 'signalEventDefinition',
  escalation: 'escalationEventDefinition',
  compensation: 'compensateEventDefinition',
  link: 'linkEventDefinition',
  error: 'errorEventDefinition',
  cancel: 'cancelEventDefinition',
  terminate: 'terminateEventDefinition'
}

export const escapeXml = (value) => String(value ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' }[c]))

// XML ids must start with a letter or underscore, and are one namespace for
// the whole file — while the contract only keeps ids unique per kind, so
// lanes and connections carry a prefix of their own.
const xmlId = (id) => (/^[A-Za-z_]/.test(String(id)) ? String(id) : `_${id}`).replace(/[^\w.-]/g, '_')
const laneXmlId = (id) => `Lane_${xmlId(id)}`
const flowXmlId = (id) => `Flow_${xmlId(id)}`

function eventDefinitions (node) {
  const kind = node.event_definition && node.event_definition.kind
  if (!kind) return ''
  if (kind === 'multiple' || kind === 'parallel_multiple') return '<bpmn:messageEventDefinition /><bpmn:signalEventDefinition />'
  const tag = DEFINITIONS[kind]
  if (!tag) return ''
  if (kind === 'timer' && node.event_definition.expression) {
    return `<bpmn:${tag}><bpmn:timeDuration xsi:type="bpmn:tFormalExpression">${escapeXml(node.event_definition.expression)}</bpmn:timeDuration></bpmn:${tag}>`
  }
  if (kind === 'link') return `<bpmn:${tag} name="${escapeXml(node.name)}" />`
  return `<bpmn:${tag} />`
}

function element (node) {
  const known = TAGS[node.type]
  const tag = known || 'task'
  const id = xmlId(node.id)
  const attributes = [`id="${id}"`]
  if (node.type === 'text_annotation') {
    return `<bpmn:textAnnotation id="${id}"><bpmn:text>${escapeXml(node.name)}</bpmn:text></bpmn:textAnnotation>`
  }
  if (node.name && node.type !== 'group') attributes.push(`name="${escapeXml(node.name)}"`)
  if (node.type === 'sub_process' && node.reference && node.reference.id) attributes.push(`calledElement="${escapeXml(node.reference.id)}"`)
  if (node.type === 'event_based_gateway') {
    if (node.instantiate) attributes.push('instantiate="true"')
    attributes.push(`eventGatewayType="${node.event_gateway_type === 'parallel' ? 'Parallel' : 'Exclusive'}"`)
  }
  if (node.type === 'start_event' && node.event_definition && node.event_definition.kind === 'parallel_multiple') attributes.push('parallelMultiple="true"')
  if (node.type === 'data_object' || node.type === 'data_collection' || node.type === 'data_input' || node.type === 'data_output') {
    attributes.push(`dataObjectRef="${id}_object"`)
  }
  const children = []
  if (node.documentation) children.push(`<bpmn:documentation>${escapeXml(node.documentation)}</bpmn:documentation>`)
  if (!known) children.push(`<bpmn:extensionElements><bali:element type="${escapeXml(node.type)}" /></bpmn:extensionElements>`)
  children.push(eventDefinitions(node))
  const body = children.join('')
  const dataObject = attributes.some((a) => a.startsWith('dataObjectRef'))
    ? `<bpmn:dataObject id="${id}_object"${node.type === 'data_collection' ? ' isCollection="true"' : ''} />`
    : ''
  return `${dataObject}<bpmn:${tag} ${attributes.join(' ')}${body ? `>${body}</bpmn:${tag}>` : ' />'}`
}

export function toBpmnXml (doc, { name = '' } = {}) {
  const layout = layoutLanes(doc)
  const origin = poolOrigin(doc)
  const routes = routeAll(doc)
  const externalLanes = layout.entries.filter((e) => e.lane.kind === 'external')
  const internalLanes = layout.entries.filter((e) => e.lane.kind !== 'external')
  const externalIds = new Set(externalLanes.map((e) => String(e.id)))
  const inExternal = (node) => node.lane_id != null && externalIds.has(String(node.lane_id))
  const byId = new Map((doc.nodes || []).map((n) => [String(n.id), n]))
  const processOf = (node) => (node && inExternal(node) ? `Process_${xmlId(node.lane_id)}` : 'Process_main')

  const flows = (doc.edges || []).filter((e) => byId.has(String(e.source)) && byId.has(String(e.target)))
  const sequence = flows.filter((e) => edgeType(e) === 'sequence_flow')
  const messages = flows.filter((e) => edgeType(e) === 'message_flow')
  const associations = flows.filter((e) => edgeType(e) === 'association')
  const flowXml = (e) => `<bpmn:sequenceFlow id="${flowXmlId(e.id)}" sourceRef="${xmlId(e.source)}" targetRef="${xmlId(e.target)}"${e.label ? ` name="${escapeXml(e.label)}"` : ''} />`
  const associationXml = (e) => `<bpmn:association id="${flowXmlId(e.id)}" sourceRef="${xmlId(e.source)}" targetRef="${xmlId(e.target)}" />`

  // The XSD lists a process's flow elements (nodes, data references, sequence
  // flows) before its artifacts (annotations, groups, associations).
  const process = (processId, nodes, laneSet) => [
    `  <bpmn:process id="${processId}" isExecutable="false">`,
    laneSet,
    ...nodes.filter((n) => n.type !== 'text_annotation' && n.type !== 'group').map((n) => `    ${element(n)}`),
    ...sequence.filter((e) => processOf(byId.get(String(e.source))) === processId).map((e) => `    ${flowXml(e)}`),
    ...nodes.filter((n) => n.type === 'text_annotation' || n.type === 'group').map((n) => `    ${element(n)}`),
    ...associations.filter((e) => processOf(byId.get(String(e.source))) === processId).map((e) => `    ${associationXml(e)}`),
    '  </bpmn:process>'
  ].filter(Boolean).join('\n')

  const mainNodes = (doc.nodes || []).filter((n) => !inExternal(n))
  const laneSet = internalLanes.length
    ? [
        '    <bpmn:laneSet id="LaneSet_main">',
        ...internalLanes.map((e) => [
          `      <bpmn:lane id="${laneXmlId(e.id)}" name="${escapeXml(e.lane.name)}">`,
          ...mainNodes.filter((n) => String(n.lane_id) === String(e.id) && isFlowNode(n)).map((n) => `        <bpmn:flowNodeRef>${xmlId(n.id)}</bpmn:flowNodeRef>`),
          '      </bpmn:lane>'
        ].join('\n')),
        '    </bpmn:laneSet>'
      ].join('\n')
    : ''

  const participants = [
    `    <bpmn:participant id="Participant_main" name="${escapeXml(name)}" processRef="Process_main" />`,
    ...externalLanes.map((e) => `    <bpmn:participant id="Participant_${xmlId(e.id)}" name="${escapeXml(e.lane.name)}" processRef="Process_${xmlId(e.id)}" />`),
    ...messages.map((e) => `    <bpmn:messageFlow id="${flowXmlId(e.id)}" sourceRef="${xmlId(e.source)}" targetRef="${xmlId(e.target)}"${e.label ? ` name="${escapeXml(e.label)}"` : ''} />`)
  ]

  // DI, in absolute canvas coordinates.
  const bounds = (r) => `<dc:Bounds x="${Math.round(origin.x + r.x)}" y="${Math.round(origin.y + r.y)}" width="${Math.round(r.w)}" height="${Math.round(r.h)}" />`
  const horizontal = layout.axis.main === 'y'
  const internalBox = internalLanes.length
    ? internalLanes.reduce((box, e) => {
      const r = laneRect(layout, e)
      return box ? { x: Math.min(box.x, r.x), y: Math.min(box.y, r.y), w: Math.max(box.x + box.w, r.x + r.w) - Math.min(box.x, r.x), h: Math.max(box.y + box.h, r.y + r.h) - Math.min(box.y, r.y) } : r
    }, null)
    : null
  const shapes = [
    internalBox && `      <bpmndi:BPMNShape id="Participant_main_di" bpmnElement="Participant_main" isHorizontal="${horizontal}">${bounds(internalBox)}</bpmndi:BPMNShape>`,
    ...externalLanes.map((e) => `      <bpmndi:BPMNShape id="Participant_${xmlId(e.id)}_di" bpmnElement="Participant_${xmlId(e.id)}" isHorizontal="${horizontal}">${bounds(laneRect(layout, e))}</bpmndi:BPMNShape>`),
    ...internalLanes.map((e) => `      <bpmndi:BPMNShape id="${laneXmlId(e.id)}_di" bpmnElement="${laneXmlId(e.id)}" isHorizontal="${horizontal}">${bounds(laneRect(layout, e))}</bpmndi:BPMNShape>`),
    ...(doc.nodes || []).map((n) => `      <bpmndi:BPMNShape id="${xmlId(n.id)}_di" bpmnElement="${xmlId(n.id)}">${bounds(nodeBox(n))}</bpmndi:BPMNShape>`)
  ].filter(Boolean)
  const edges = flows.map((e) => {
    const route = routes.get(String(e.id))
    if (!route) return ''
    const points = route.points.map((p) => `<di:waypoint x="${Math.round(origin.x + p.x)}" y="${Math.round(origin.y + p.y)}" />`).join('')
    return `      <bpmndi:BPMNEdge id="${flowXmlId(e.id)}_di" bpmnElement="${flowXmlId(e.id)}">${points}</bpmndi:BPMNEdge>`
  }).filter(Boolean)

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"',
    '  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI"',
    '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:bali="https://github.com/Grupo-AFAL/bali-view-components/bpmn"',
    '  id="Definitions_1" targetNamespace="http://bpmn.io/schema/bpmn" exporter="Bali::BpmnEditor">',
    '  <bpmn:collaboration id="Collaboration_1">',
    ...participants,
    '  </bpmn:collaboration>',
    process('Process_main', mainNodes, laneSet),
    ...externalLanes.map((e) => process(`Process_${xmlId(e.id)}`, (doc.nodes || []).filter((n) => String(n.lane_id) === String(e.id)), '')),
    '  <bpmndi:BPMNDiagram id="Diagram_1">',
    '    <bpmndi:BPMNPlane id="Plane_1" bpmnElement="Collaboration_1">',
    ...shapes,
    ...edges,
    '    </bpmndi:BPMNPlane>',
    '  </bpmndi:BPMNDiagram>',
    '</bpmn:definitions>',
    ''
  ].join('\n')
}
