// The BPMN vocabulary the editor understands: node types with their default
// box, and the palette items that create them.
//
// PALETTE_ITEMS is a contract with Ruby: Bali::BpmnEditor::Palette::KEYS
// lists exactly these keys and owns the presets (palette.rb), and
// test/bali/components/bpmn_editor/palette_test.rb reads this file to keep
// both sides equal.

export const CATEGORY = {
  activity: 'activity',
  gateway: 'gateway',
  event: 'event',
  artifact: 'artifact',
  data: 'data',
  unknown: 'unknown'
}

const activity = (width = 150, height = 64) => ({ category: CATEGORY.activity, width, height })
const gateway = { category: CATEGORY.gateway, width: 50, height: 50 }
const event = { category: CATEGORY.event, width: 36, height: 36 }

export const NODE_TYPES = {
  task: activity(),
  user_task: activity(),
  service_task: activity(),
  send_task: activity(),
  receive_task: activity(),
  script_task: activity(),
  business_rule_task: activity(),
  manual_task: activity(),
  sub_process: activity(),
  exclusive_gateway: gateway,
  parallel_gateway: gateway,
  inclusive_gateway: gateway,
  complex_gateway: gateway,
  event_based_gateway: gateway,
  start_event: event,
  intermediate_catch_event: event,
  intermediate_throw_event: event,
  end_event: event,
  text_annotation: { category: CATEGORY.artifact, width: 130, height: 50 },
  group: { category: CATEGORY.artifact, width: 240, height: 150 },
  data_object: { category: CATEGORY.data, width: 36, height: 48 },
  data_input: { category: CATEGORY.data, width: 36, height: 48 },
  data_output: { category: CATEGORY.data, width: 36, height: 48 },
  data_collection: { category: CATEGORY.data, width: 36, height: 48 },
  data_store: { category: CATEGORY.data, width: 50, height: 48 }
}

const UNKNOWN = { category: CATEGORY.unknown, width: 120, height: 60 }

export const typeInfo = (type) => NODE_TYPES[type] || UNKNOWN
export const categoryOf = (node) => typeInfo(node && node.type).category
export const isActivity = (node) => categoryOf(node) === CATEGORY.activity
export const isGateway = (node) => categoryOf(node) === CATEGORY.gateway
// The binary decision ("blue diamond"): an exclusive gateway drawn without
// its X (BPMN DI isMarkerVisible="false"), two answers to one question.
export const isBinaryDecision = (node) => Boolean(node) && node.type === 'exclusive_gateway' && node.marker_visible === false
export const isEvent = (node) => categoryOf(node) === CATEGORY.event
export const isStart = (node) => node && node.type === 'start_event'
export const isEnd = (node) => node && node.type === 'end_event'
// Artifacts and data elements sit outside the sequence flow: they never take
// a sequence flow, and an association always has one at an end.
export const isArtifactLike = (node) => {
  const category = categoryOf(node)
  return category === CATEGORY.artifact || category === CATEGORY.data
}
export const isFlowNode = (node) => {
  const category = categoryOf(node)
  return category === CATEGORY.activity || category === CATEGORY.gateway || category === CATEGORY.event
}

export const nodeSize = (node) => {
  const info = typeInfo(node.type)
  return {
    width: Number(node.width) > 0 ? Number(node.width) : info.width,
    height: Number(node.height) > 0 ? Number(node.height) : info.height
  }
}

// The nodes a person may resize: the activities, whose name is drawn inside
// the box. An event or a gateway is a symbol of fixed size (BPMN 2.0, Method
// and Style). The limits keep the name, the corner markers and the [+]
// inside the box, and one box from swallowing a lane. They bound the handle
// and the properties panel, not the document: Bali::BpmnEditor::Data only
// requires a positive size, since the catalog preview draws activities at
// their 28 px icon size.
export const MIN_NODE_SIZE = { width: 80, height: 40 }
export const MAX_NODE_SIZE = { width: 800, height: 400 }
export const isResizable = (node) => isActivity(node)
// «Auto»: no width or height of its own (absent or null), so the box takes
// its type's default.
export const hasOwnSize = (node) => Number(node.width) > 0 || Number(node.height) > 0

// Events and gateways print their name under the shape, so the label needs
// room the box does not include (lanes grow by it, overlap counts it).
export const labelExtent = (node) => (isEvent(node) || isGateway(node) || categoryOf(node) === CATEGORY.data ? 30 : 0)

// Mirrors Bali::BpmnEditor::Data::EDGE_TYPES (contract_test.rb).
export const EDGE_TYPES = ['sequence_flow', 'message_flow', 'association']
export const edgeType = (edge) => (EDGE_TYPES.includes(edge && edge.type) ? edge.type : 'sequence_flow')

export const PALETTE_GROUPS = [
  'activities', 'gateways', 'swimlanes', 'connectors', 'artifacts',
  'start_events', 'intermediate_events', 'end_events'
]

const ev = (type, kind) => ({ type, event_definition: kind ? { kind } : undefined })

// key → { group, node attributes it creates }. `lane` and the connectors do
// not create nodes: the palette routes them to their own tools.
export const PALETTE_ITEMS = {
  task: { group: 'activities', node: { type: 'task' } },
  user_task: { group: 'activities', node: { type: 'user_task' } },
  service_task: { group: 'activities', node: { type: 'service_task' } },
  send_task: { group: 'activities', node: { type: 'send_task' } },
  receive_task: { group: 'activities', node: { type: 'receive_task' } },
  script_task: { group: 'activities', node: { type: 'script_task' } },
  business_rule_task: { group: 'activities', node: { type: 'business_rule_task' } },
  manual_task: { group: 'activities', node: { type: 'manual_task' } },
  sub_process: { group: 'activities', node: { type: 'sub_process' } },
  binary_decision: { group: 'gateways', node: { type: 'exclusive_gateway', marker_visible: false } },
  exclusive_gateway: { group: 'gateways', node: { type: 'exclusive_gateway' } },
  parallel_gateway: { group: 'gateways', node: { type: 'parallel_gateway' } },
  inclusive_gateway: { group: 'gateways', node: { type: 'inclusive_gateway' } },
  complex_gateway: { group: 'gateways', node: { type: 'complex_gateway' } },
  event_based_gateway: { group: 'gateways', node: { type: 'event_based_gateway' } },
  event_based_start_gateway: { group: 'gateways', node: { type: 'event_based_gateway', instantiate: true } },
  parallel_event_based_gateway: { group: 'gateways', node: { type: 'event_based_gateway', instantiate: true, event_gateway_type: 'parallel' } },
  lane: { group: 'swimlanes', tool: 'lane' },
  sequence_flow: { group: 'connectors', tool: 'connect', edge: 'sequence_flow' },
  message_flow: { group: 'connectors', tool: 'connect', edge: 'message_flow' },
  association: { group: 'connectors', tool: 'connect', edge: 'association' },
  text_annotation: { group: 'artifacts', node: { type: 'text_annotation' } },
  group: { group: 'artifacts', node: { type: 'group' } },
  data_object: { group: 'artifacts', node: { type: 'data_object' } },
  data_collection: { group: 'artifacts', node: { type: 'data_collection' } },
  data_input: { group: 'artifacts', node: { type: 'data_input' } },
  data_output: { group: 'artifacts', node: { type: 'data_output' } },
  data_store: { group: 'artifacts', node: { type: 'data_store' } },
  start_event: { group: 'start_events', node: ev('start_event') },
  timer_start_event: { group: 'start_events', node: ev('start_event', 'timer') },
  message_start_event: { group: 'start_events', node: ev('start_event', 'message') },
  conditional_start_event: { group: 'start_events', node: ev('start_event', 'conditional') },
  signal_start_event: { group: 'start_events', node: ev('start_event', 'signal') },
  multiple_start_event: { group: 'start_events', node: ev('start_event', 'multiple') },
  parallel_multiple_start_event: { group: 'start_events', node: ev('start_event', 'parallel_multiple') },
  timer_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'timer') },
  message_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'message') },
  message_throw_event: { group: 'intermediate_events', node: ev('intermediate_throw_event', 'message') },
  escalation_event: { group: 'intermediate_events', node: ev('intermediate_throw_event', 'escalation') },
  compensation_event: { group: 'intermediate_events', node: ev('intermediate_throw_event', 'compensation') },
  conditional_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'conditional') },
  link_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'link') },
  link_throw_event: { group: 'intermediate_events', node: ev('intermediate_throw_event', 'link') },
  signal_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'signal') },
  signal_throw_event: { group: 'intermediate_events', node: ev('intermediate_throw_event', 'signal') },
  multiple_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'multiple') },
  parallel_multiple_event: { group: 'intermediate_events', node: ev('intermediate_catch_event', 'parallel_multiple') },
  end_event: { group: 'end_events', node: ev('end_event') },
  message_end_event: { group: 'end_events', node: ev('end_event', 'message') },
  error_end_event: { group: 'end_events', node: ev('end_event', 'error') },
  cancel_end_event: { group: 'end_events', node: ev('end_event', 'cancel') },
  compensation_end_event: { group: 'end_events', node: ev('end_event', 'compensation') },
  signal_end_event: { group: 'end_events', node: ev('end_event', 'signal') },
  terminate_end_event: { group: 'end_events', node: ev('end_event', 'terminate') },
  multiple_end_event: { group: 'end_events', node: ev('end_event', 'multiple') },
  escalation_end_event: { group: 'end_events', node: ev('end_event', 'escalation') }
}

// The palette key a node would have been created from — used to label a
// node in the properties panel with the same name the palette shows.
export function paletteKeyFor (node) {
  const kind = node.event_definition && node.event_definition.kind
  for (const [key, item] of Object.entries(PALETTE_ITEMS)) {
    if (!item.node || item.node.type !== node.type) continue
    const itemKind = item.node.event_definition && item.node.event_definition.kind
    if ((itemKind || null) !== (kind || null)) continue
    if (item.node.type === 'exclusive_gateway' && (item.node.marker_visible === false) !== (node.marker_visible === false)) continue
    if (item.node.type === 'event_based_gateway') {
      const instantiate = !!node.instantiate
      const parallel = node.event_gateway_type === 'parallel'
      if (!!item.node.instantiate !== instantiate || (item.node.event_gateway_type === 'parallel') !== parallel) continue
    }
    return key
  }
  return null
}
