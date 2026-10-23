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
import { edgeType, isFlowNode, isBinaryDecision } from './catalog.js'
import { appearanceOf } from './appearance.js'
import { parseHex } from './contrast.js'

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
// the whole file. Lanes and connections carry a prefix of their own, which
// keeps the ids of files already exported.
const xmlId = (id) => (/^[A-Za-z_]/.test(String(id)) ? String(id) : `_${id}`).replace(/[^\w.-]/g, '_')

// xmlId maps distinct ids to one ("a b" and "a_b", "1" and "_1", two
// non-ASCII ids of one length), a prefixed id can meet an unprefixed one (a
// lane "main" and the main participant, a node "Lane_x" and a lane "x"), and
// so can a derived id (a node "a_di" and node a's shape). Each id is claimed in document order; one
// already taken gets the first free `_2`, `_3`…, so an export without
// collisions keeps its ids and the same document always exports the same.
function idRegistry () {
  const taken = new Set()
  return (candidate) => {
    let id = candidate
    for (let n = 2; taken.has(id); n++) id = `${candidate}_${n}`
    taken.add(id)
    return id
  }
}

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

function element (node, id, objectId) {
  const known = TAGS[node.type]
  const tag = known || 'task'
  const attributes = [`id="${id}"`]
  if (node.type === 'text_annotation') {
    return `<bpmn:textAnnotation id="${id}"><bpmn:text>${escapeXml(node.name)}</bpmn:text></bpmn:textAnnotation>`
  }
  if (node.name && node.type !== 'group') attributes.push(`name="${escapeXml(node.name)}"`)
  // calledElement is an xsd:QName, which cannot start with a digit: a host's
  // numeric id ("101") goes out as "_101", like every other id here.
  if (node.type === 'sub_process' && node.reference && node.reference.id) attributes.push(`calledElement="${escapeXml(xmlId(node.reference.id))}"`)
  if (node.type === 'event_based_gateway') {
    if (node.instantiate) attributes.push('instantiate="true"')
    attributes.push(`eventGatewayType="${node.event_gateway_type === 'parallel' ? 'Parallel' : 'Exclusive'}"`)
  }
  if (node.type === 'start_event' && node.event_definition && node.event_definition.kind === 'parallel_multiple') attributes.push('parallelMultiple="true"')
  if (node.type === 'data_object' || node.type === 'data_collection' || node.type === 'data_input' || node.type === 'data_output') {
    attributes.push(`dataObjectRef="${objectId}"`)
  }
  const children = []
  if (node.documentation) children.push(`<bpmn:documentation>${escapeXml(node.documentation)}</bpmn:documentation>`)
  if (!known) children.push(`<bpmn:extensionElements><bali:element type="${escapeXml(node.type)}" /></bpmn:extensionElements>`)
  children.push(eventDefinitions(node))
  const body = children.join('')
  const dataObject = attributes.some((a) => a.startsWith('dataObjectRef'))
    ? `<bpmn:dataObject id="${objectId}"${node.type === 'data_collection' ? ' isCollection="true"' : ''} />`
    : ''
  return `${dataObject}<bpmn:${tag} ${attributes.join(' ')}${body ? `>${body}</bpmn:${tag}>` : ' />'}`
}

// The app's colour (`node.appearance.color`) in the diagram interchange, the
// way modelling tools read it:
//   - BPMN in Color (OMG, BPMN MIWG, 2018): `color:border-color` and
//     `color:background-color` on the BPMNShape — what the specification names;
//   - bpmn.io's `bioc:stroke` and `bioc:fill` — what bpmn-js and Camunda
//     Modeler read and write (they write both pairs).
// The fill is the tint the canvas paints (16 % of the colour over white). The
// namespaces are declared only when a node has a colour, so a document without
// one exports exactly as before. `dimmed` and `badge` are not exported: no
// interchange format has them.
export const COLOR_NAMESPACES = {
  color: 'http://www.omg.org/spec/BPMN/non-normative/color/1.0',
  bioc: 'http://bpmn.io/schema/bpmn/biocolor/1.0'
}
const TINT = 0.16
const hex = (rgb) => `#${rgb.map((c) => Math.round(c).toString(16).padStart(2, '0')).join('')}`
function colorsOf (node) {
  const look = appearanceOf(node)
  const rgb = look && look.color && parseHex(look.color)
  if (!rgb) return null
  return { stroke: hex(rgb), fill: hex(rgb.map((c) => 255 + (c - 255) * TINT)) }
}
const colorAttributes = (colors) => (colors
  ? ` bioc:stroke="${colors.stroke}" bioc:fill="${colors.fill}" color:border-color="${colors.stroke}" color:background-color="${colors.fill}"`
  : '')

export function toBpmnXml (doc, { name = '' } = {}) {
  const layout = layoutLanes(doc)
  const origin = poolOrigin(doc)
  const routes = routeAll(doc)
  const externalLanes = layout.entries.filter((e) => e.lane.kind === 'external')
  const internalLanes = layout.entries.filter((e) => e.lane.kind !== 'external')
  const externalIds = new Set(externalLanes.map((e) => String(e.id)))
  const inExternal = (node) => node.lane_id != null && externalIds.has(String(node.lane_id))
  const byId = new Map((doc.nodes || []).map((n) => [String(n.id), n]))
  const flows = (doc.edges || []).filter((e) => byId.has(String(e.source)) && byId.has(String(e.target)))

  // Every id of the file, claimed before any is written: the fixed ones
  // first, then the elements', then the ones derived from those.
  const claim = idRegistry()
  for (const fixed of ['Definitions_1', 'Collaboration_1', 'Diagram_1', 'Plane_1', 'LaneSet_main']) claim(fixed)
  const main = { participant: claim('Participant_main'), process: claim('Process_main') }
  const pool = new Map(externalLanes.map((e) => [String(e.id), { participant: claim(`Participant_${xmlId(e.id)}`), process: claim(`Process_${xmlId(e.id)}`) }]))
  const laneIds = new Map(internalLanes.map((e) => [String(e.id), claim(`Lane_${xmlId(e.id)}`)]))
  const nodeIds = new Map((doc.nodes || []).map((n) => [String(n.id), claim(xmlId(n.id))]))
  const flowIds = new Map(flows.map((e) => [String(e.id), claim(`Flow_${xmlId(e.id)}`)]))
  const objectIds = new Map((doc.nodes || []).filter((n) => n.type === 'data_object' || n.type === 'data_collection' || n.type === 'data_input' || n.type === 'data_output')
    .map((n) => [String(n.id), claim(`${nodeIds.get(String(n.id))}_object`)]))
  const shapeOf = new Map([...[main, ...pool.values()].map((p) => p.participant), ...laneIds.values(), ...nodeIds.values(), ...flowIds.values()].map((id) => [id, claim(`${id}_di`)]))
  const nodeId = (id) => nodeIds.get(String(id))
  const flowId = (e) => flowIds.get(String(e.id))
  const node = (n) => element(n, nodeId(n.id), objectIds.get(String(n.id)))
  const processOf = (n) => (n && inExternal(n) ? pool.get(String(n.lane_id)).process : main.process)
  const sequence = flows.filter((e) => edgeType(e) === 'sequence_flow')
  const messages = flows.filter((e) => edgeType(e) === 'message_flow')
  const associations = flows.filter((e) => edgeType(e) === 'association')
  const flowXml = (e) => `<bpmn:sequenceFlow id="${flowId(e)}" sourceRef="${nodeId(e.source)}" targetRef="${nodeId(e.target)}"${e.label ? ` name="${escapeXml(e.label)}"` : ''} />`
  const associationXml = (e) => `<bpmn:association id="${flowId(e)}" sourceRef="${nodeId(e.source)}" targetRef="${nodeId(e.target)}" />`

  // The XSD lists a process's flow elements (nodes, data references, sequence
  // flows) before its artifacts (annotations, groups, associations).
  const process = (processId, nodes, laneSet) => [
    `  <bpmn:process id="${processId}" isExecutable="false">`,
    laneSet,
    ...nodes.filter((n) => n.type !== 'text_annotation' && n.type !== 'group').map((n) => `    ${node(n)}`),
    ...sequence.filter((e) => processOf(byId.get(String(e.source))) === processId).map((e) => `    ${flowXml(e)}`),
    ...nodes.filter((n) => n.type === 'text_annotation' || n.type === 'group').map((n) => `    ${node(n)}`),
    ...associations.filter((e) => processOf(byId.get(String(e.source))) === processId).map((e) => `    ${associationXml(e)}`),
    '  </bpmn:process>'
  ].filter(Boolean).join('\n')

  const mainNodes = (doc.nodes || []).filter((n) => !inExternal(n))
  const laneSet = internalLanes.length
    ? [
        '    <bpmn:laneSet id="LaneSet_main">',
        ...internalLanes.map((e) => [
          `      <bpmn:lane id="${laneIds.get(String(e.id))}" name="${escapeXml(e.lane.name)}">`,
          ...mainNodes.filter((n) => String(n.lane_id) === String(e.id) && isFlowNode(n)).map((n) => `        <bpmn:flowNodeRef>${nodeId(n.id)}</bpmn:flowNodeRef>`),
          '      </bpmn:lane>'
        ].join('\n')),
        '    </bpmn:laneSet>'
      ].join('\n')
    : ''

  const participants = [
    `    <bpmn:participant id="${main.participant}" name="${escapeXml(name)}" processRef="${main.process}" />`,
    ...externalLanes.map((e) => `    <bpmn:participant id="${pool.get(String(e.id)).participant}" name="${escapeXml(e.lane.name)}" processRef="${pool.get(String(e.id)).process}" />`),
    ...messages.map((e) => `    <bpmn:messageFlow id="${flowId(e)}" sourceRef="${nodeId(e.source)}" targetRef="${nodeId(e.target)}"${e.label ? ` name="${escapeXml(e.label)}"` : ''} />`)
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
  const shape = (element, attributes, box) => `      <bpmndi:BPMNShape id="${shapeOf.get(element)}" bpmnElement="${element}"${attributes}>${bounds(box)}</bpmndi:BPMNShape>`
  const shapes = [
    internalBox && shape(main.participant, ` isHorizontal="${horizontal}"`, internalBox),
    ...externalLanes.map((e) => shape(pool.get(String(e.id)).participant, ` isHorizontal="${horizontal}"`, laneRect(layout, e))),
    ...internalLanes.map((e) => shape(laneIds.get(String(e.id)), ` isHorizontal="${horizontal}"`, laneRect(layout, e))),
    // The Yes/No decision is an exclusive gateway whose X is hidden: BPMN DI
    // says so with isMarkerVisible, the one place the standard keeps it.
    ...(doc.nodes || []).map((n) => shape(nodeId(n.id), `${n.type === 'exclusive_gateway' ? ` isMarkerVisible="${!isBinaryDecision(n)}"` : ''}${colorAttributes(colorsOf(n))}`, nodeBox(n)))
  ].filter(Boolean)
  const edges = flows.map((e) => {
    const route = routes.get(String(e.id))
    if (!route) return ''
    const points = route.points.map((p) => `<di:waypoint x="${Math.round(origin.x + p.x)}" y="${Math.round(origin.y + p.y)}" />`).join('')
    return `      <bpmndi:BPMNEdge id="${shapeOf.get(flowId(e))}" bpmnElement="${flowId(e)}">${points}</bpmndi:BPMNEdge>`
  }).filter(Boolean)

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"',
    '  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI"',
    '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:bali="https://github.com/Grupo-AFAL/bali-view-components/bpmn"',
    (doc.nodes || []).some(colorsOf) && `  xmlns:bioc="${COLOR_NAMESPACES.bioc}" xmlns:color="${COLOR_NAMESPACES.color}"`,
    '  id="Definitions_1" targetNamespace="http://bpmn.io/schema/bpmn" exporter="Bali::BpmnEditor">',
    '  <bpmn:collaboration id="Collaboration_1">',
    ...participants,
    '  </bpmn:collaboration>',
    process(main.process, mainNodes, laneSet),
    ...externalLanes.map((e) => process(pool.get(String(e.id)).process, (doc.nodes || []).filter((n) => String(n.lane_id) === String(e.id)), '')),
    '  <bpmndi:BPMNDiagram id="Diagram_1">',
    '    <bpmndi:BPMNPlane id="Plane_1" bpmnElement="Collaboration_1">',
    ...shapes,
    ...edges,
    '    </bpmndi:BPMNPlane>',
    '  </bpmndi:BPMNDiagram>',
    '</bpmn:definitions>',
    ''
  ].filter((line) => line !== false).join('\n')
}
