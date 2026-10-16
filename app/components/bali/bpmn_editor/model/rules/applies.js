// What each rule looks at, as palette keys (PALETTE_ITEMS in ../catalog.js):
// a rule's `appliesTo` lists the elements its check inspects, so the catalog
// can say which rules an element is held to without a hand-kept list.
//
// Convention for rules about the diagram as a whole: a rule that counts
// elements applies to the keys it counts (R12 start and end events, R19/R20
// activities, R21 lanes); a rule about the drawing as such (VIS-02, the page
// fit) applies to `lane`, the band the whole flow is drawn in.
import { PALETTE_ITEMS, categoryOf, isActivity, isFlowNode, isArtifactLike, isBinaryDecision } from '../catalog.js'

const NODE_ITEMS = Object.entries(PALETTE_ITEMS).filter(([, item]) => item.node)
const keysWhere = (test) => NODE_ITEMS.filter(([, item]) => test(item.node)).map(([key]) => key)
const kindOf = (node) => (node.event_definition && node.event_definition.kind) || null

// Elements of a given type, optionally only with one of `kinds` of event
// definition (null = the plain event).
export const byType = (...types) => keysWhere((node) => types.includes(node.type))
export const byKind = (types, kinds) => keysWhere((node) => types.includes(node.type) && kinds.includes(kindOf(node)))

export const NODE_KEYS = NODE_ITEMS.map(([key]) => key)
export const ACTIVITY_KEYS = keysWhere(isActivity)
export const TASK_KEYS = keysWhere((node) => isActivity(node) && node.type !== 'sub_process')
export const GATEWAY_KEYS = keysWhere((node) => categoryOf(node) === 'gateway')
export const FLOW_NODE_KEYS = keysWhere(isFlowNode)
export const ARTIFACT_KEYS = keysWhere(isArtifactLike)
export const START_KEYS = byType('start_event')
export const END_KEYS = byType('end_event')
export const DECISION_KEYS = byType('exclusive_gateway', 'inclusive_gateway')
export const YES_NO_KEYS = keysWhere(isBinaryDecision)
export const INSTANTIATING_GATEWAY_KEYS = keysWhere((node) => node.type === 'event_based_gateway' && Boolean(node.instantiate))
export const LANE = ['lane']
export const SEQUENCE_FLOW = ['sequence_flow']
export const MESSAGE_FLOW = ['message_flow']
export const ASSOCIATION = ['association']
export const CONNECTOR_KEYS = [...SEQUENCE_FLOW, ...MESSAGE_FLOW, ...ASSOCIATION]

// Every key a rule may name.
export const PALETTE_KEYS = Object.keys(PALETTE_ITEMS)
