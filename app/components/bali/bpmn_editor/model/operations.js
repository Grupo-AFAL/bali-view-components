// Every edit to the document, as a pure function. Each returns
// `{ doc, ...extra }` on success or `{ error, vars }` when the edit is
// blocked — `error` is the i18n key of the message the editor shows.
//
// Blocks only guard the edit being made. A document that already breaks a
// rule (an imported one, say) opens and saves untouched: the rule engine lists
// those problems as pending issues instead.
//
// Node coordinates are pool-relative and lanes stack, so anything that
// changes a lane's size or position on the main axis has to carry the nodes of
// the lanes after it along: `resizeLane` and `reorderLanes` do.
import { nodeSize, isActivity, isArtifactLike, isFlowNode, isStart, isEnd, edgeType, categoryOf, CATEGORY, isBinaryDecision } from './catalog.js'
import {
  layoutLanes, laneAt, nodeBox, boxesOverlap, laneRequiredSize, axisFor, sortedLanes, laneSize, insideLane,
  HEADER, LANE_PADDING, DEFAULT_LANE_SIZE, MIN_LANE_SIZE, orientationOf
} from './geometry.js'
import { newId, findNode, outgoing, incoming } from './document.js'

// What the editor refuses on the spot. The editor derives it from the
// enabled rules (rules.js blockPolicy), so turning a rule off also lifts its block.
export const DEFAULT_POLICY = {
  oneInOneOut: true, // R01/R02
  noOverlap: true, // R18
  insideLane: true, // R26
  minLanes: 2, // R21
  messageFlowParticipants: true, // B02
  associationArtifact: true, // B03
  noSequenceOnArtifacts: true // B04
}

const blocked = (error, vars) => ({ error, vars })
const sameId = (a, b) => String(a) === String(b)

// ── lanes ──────────────────────────────────────────────────────────────────

function shiftNodeMain (node, delta, axis) {
  if (!delta) return node
  return { ...node, [axis.main]: (Number(node[axis.main]) || 0) + delta }
}

function clearWaypointsOf (edges, ids) {
  return edges.map((e) => (ids.has(String(e.source)) || ids.has(String(e.target))) && e.waypoints && e.waypoints.length ? { ...e, waypoints: [] } : e)
}

// Changes one lane's size; the nodes of every later lane move with their lane.
export function resizeLane (doc, laneId, size) {
  const layout = layoutLanes(doc)
  const entry = layout.byId.get(String(laneId))
  if (!entry) return { doc }
  const next = Math.max(MIN_LANE_SIZE[layout.orientation], Math.round(size))
  const required = laneRequiredSize(doc, layout, laneId)
  const final = Math.max(next, required)
  const delta = final - entry.size
  if (!delta) return { doc }
  const after = new Set(layout.entries.filter((e) => e.offset > entry.offset).map((e) => String(e.id)))
  const moved = new Set()
  const nodes = doc.nodes.map((n) => {
    if (n.lane_id == null || !after.has(String(n.lane_id))) return n
    moved.add(String(n.id))
    return shiftNodeMain(n, delta, layout.axis)
  })
  return {
    doc: {
      ...doc,
      lanes: doc.lanes.map((l) => (sameId(l.id, laneId) ? { ...l, size: final } : l)),
      nodes,
      edges: clearWaypointsOf(doc.edges, moved)
    },
    clamped: final !== next
  }
}

// Grows every lane that is too small for its nodes (after a create or a move).
export function fitLanes (doc) {
  let current = doc
  for (const lane of sortedLanes(doc)) {
    const layout = layoutLanes(current)
    const entry = layout.byId.get(String(lane.id))
    const required = laneRequiredSize(current, layout, lane.id)
    if (required > entry.size) current = resizeLane(current, lane.id, required).doc
  }
  return current
}

export function addLane (doc, { name, kind = 'internal' } = {}) {
  const orientation = orientationOf(doc)
  const order = doc.lanes.reduce((max, l) => Math.max(max, Number(l.order) || 0), 0) + 1
  const lane = { id: newId(doc, 'lane_'), name: name || '', kind, order, size: DEFAULT_LANE_SIZE[orientation] }
  return { doc: { ...doc, lanes: [...doc.lanes, lane] }, id: lane.id }
}

export function updateLane (doc, laneId, patch) {
  return { doc: { ...doc, lanes: doc.lanes.map((l) => (sameId(l.id, laneId) ? { ...l, ...patch } : l)) } }
}

// New order of lanes (ids, first to last); nodes travel with their lane.
export function reorderLanes (doc, orderedIds) {
  const layout = layoutLanes(doc)
  const before = new Map(layout.entries.map((e) => [String(e.id), e.offset]))
  let offset = 0
  const after = new Map()
  for (const id of orderedIds) {
    const entry = layout.byId.get(String(id))
    if (!entry) continue
    after.set(String(id), offset)
    offset += entry.size
  }
  const moved = new Set()
  const nodes = doc.nodes.map((n) => {
    const id = n.lane_id != null ? String(n.lane_id) : null
    if (!id || !after.has(id)) return n
    const delta = after.get(id) - before.get(id)
    if (delta) moved.add(String(n.id))
    return shiftNodeMain(n, delta, layout.axis)
  })
  const position = new Map(orderedIds.map((id, i) => [String(id), i + 1]))
  return {
    doc: {
      ...doc,
      lanes: doc.lanes.map((l) => (position.has(String(l.id)) ? { ...l, order: position.get(String(l.id)) } : l)),
      nodes,
      edges: clearWaypointsOf(doc.edges, moved)
    }
  }
}

// Moves a lane one slot up/down (or left/right in vertical lanes).
export function moveLane (doc, laneId, step) {
  const ids = sortedLanes(doc).map((l) => String(l.id))
  const index = ids.indexOf(String(laneId))
  const target = index + step
  if (index < 0 || target < 0 || target >= ids.length) return { doc }
  ;[ids[index], ids[target]] = [ids[target], ids[index]]
  return reorderLanes(doc, ids)
}

export function movePool (doc, dx, dy) {
  const pool = doc.pool || {}
  return { doc: { ...doc, pool: { ...pool, x: Math.round((Number(pool.x) || 0) + dx), y: Math.round((Number(pool.y) || 0) + dy) } } }
}

export function setPoolLength (doc, length) {
  return { doc: { ...doc, pool: { ...(doc.pool || {}), length: Math.round(length) } } }
}

// ── nodes ──────────────────────────────────────────────────────────────────

const OVERLAP_MARGIN = 4

// Groups frame other elements on purpose, so they never "overlap".
function overlapping (doc, ids) {
  const moving = doc.nodes.filter((n) => ids.has(String(n.id)) && n.type !== 'group')
  const others = doc.nodes.filter((n) => !ids.has(String(n.id)) && n.type !== 'group')
  return moving.some((a) => others.some((b) => boxesOverlap(nodeBox(a), nodeBox(b), OVERLAP_MARGIN)))
}

// Places a box inside the lane under its centre: clear of the header, inside
// the band (the band grows later in fitLanes if the node does not fit).
function placeInLane (node, layout) {
  const box = nodeBox(node)
  const { axis, header } = layout
  const center = { x: box.cx, y: box.cy }
  const entry = laneAt(layout, center)
  if (!entry) return null
  const mainSize = axis.main === 'y' ? box.h : box.w
  const crossStart = axis.cross === 'x' ? box.x : box.y
  const mainStart = Math.max(entry.offset + LANE_PADDING, axis.main === 'y' ? box.y : box.x)
  const fixedCross = Math.max(header + LANE_PADDING, crossStart)
  const placed = { ...node, lane_id: entry.id }
  placed[axis.main] = Math.round(mainSize > entry.size ? entry.offset + LANE_PADDING : mainStart)
  placed[axis.cross] = Math.round(fixedCross)
  return placed
}

// `attrs` come from the palette item (type, event_definition…); `center` is
// pool-relative. `names` maps a family to the default name (i18n).
export function createNode (doc, attrs, center, { policy = DEFAULT_POLICY, names = {} } = {}) {
  const layout = layoutLanes(doc)
  const { width, height } = nodeSize(attrs)
  const draft = { name: defaultName(attrs, names), ...attrs, id: newId(doc, 'n_'), x: Math.round(center.x - width / 2), y: Math.round(center.y - height / 2) }
  let node = draft
  if (layout.entries.length && !isArtifactLike(draft)) {
    node = placeInLane(draft, layout)
    if (!node) return blocked('block_lane')
  } else if (layout.entries.length) {
    const entry = laneAt(layout, center)
    node = entry ? { ...draft, lane_id: entry.id } : draft
  }
  let next = { ...doc, nodes: [...doc.nodes, node] }
  if (policy.noOverlap && overlapping(next, new Set([String(node.id)]))) return blocked('block_overlap')
  next = fitLanes(next)
  return { doc: next, id: node.id }
}

export function defaultName (attrs, names) {
  const category = categoryOf(attrs)
  if (attrs.type === 'sub_process') return names.sub_process || ''
  if (category === CATEGORY.activity) return names.task || ''
  if (category === CATEGORY.gateway) return names.gateway || ''
  if (attrs.type === 'start_event') return names.start || ''
  if (attrs.type === 'end_event') return names.end || ''
  if (category === CATEGORY.event) return names.event || ''
  if (attrs.type === 'text_annotation') return names.annotation || ''
  if (category === CATEGORY.data) return names.data || ''
  return ''
}

// Moves nodes by a delta (pool-relative). Each node lands in the lane under its
// centre; a lane too small for it grows.
export function moveNodes (doc, ids, delta, { policy = DEFAULT_POLICY } = {}) {
  const idSet = new Set([...ids].map(String))
  const layout = layoutLanes(doc)
  const hasLanes = layout.entries.length > 0
  let failed = null
  const nodes = doc.nodes.map((n) => {
    if (failed || !idSet.has(String(n.id))) return n
    const moved = { ...n, x: Math.round((Number(n.x) || 0) + delta.x), y: Math.round((Number(n.y) || 0) + delta.y) }
    if (!hasLanes) return moved
    if (isArtifactLike(moved)) {
      const entry = laneAt(layout, { x: nodeBox(moved).cx, y: nodeBox(moved).cy })
      return { ...moved, lane_id: entry ? entry.id : null }
    }
    const placed = placeInLane(moved, layout)
    if (!placed) {
      if (policy.insideLane) failed = 'block_lane'
      return moved
    }
    const crossOf = (node) => node[layout.axis.cross]
    if (policy.insideLane && Math.abs(crossOf(placed) - crossOf(moved)) > 0.5) failed = 'block_lane'
    return placed
  })
  if (failed) return blocked(failed)
  let next = { ...doc, nodes, edges: clearWaypointsOf(doc.edges, idSet) }
  if (policy.noOverlap && overlapping(next, idSet)) return blocked('block_overlap')
  next = fitLanes(next)
  return { doc: next }
}

export function updateNode (doc, id, patch) {
  return { doc: { ...doc, nodes: doc.nodes.map((n) => (sameId(n.id, id) ? { ...n, ...patch } : n)) } }
}

export function updateEdge (doc, id, patch) {
  return { doc: { ...doc, edges: doc.edges.map((e) => (sameId(e.id, id) ? { ...e, ...patch } : e)) } }
}

// ── connections ────────────────────────────────────────────────────────────

// The participant a node belongs to for message flows: an external lane is a
// participant of its own; every internal lane is part of the one process.
function participantOf (doc, node) {
  const lane = node.lane_id != null ? doc.lanes.find((l) => sameId(l.id, node.lane_id)) : null
  return lane && lane.kind === 'external' ? `external:${lane.id}` : 'process'
}

// Why a connection may not be made, or null. `ignoreEdgeId` excludes an edge
// being reconnected from the counts.
export function connectionError (doc, sourceId, targetId, { type = 'sequence_flow', policy = DEFAULT_POLICY, ignoreEdgeId = null } = {}) {
  const source = findNode(doc, sourceId)
  const target = findNode(doc, targetId)
  if (!source || !target) return 'block_connection'
  if (sameId(source.id, target.id)) return 'block_self'
  const edges = doc.edges.filter((e) => !sameId(e.id, ignoreEdgeId))
  if (edges.some((e) => sameId(e.source, source.id) && sameId(e.target, target.id) && edgeType(e) === type)) return 'block_duplicate'
  if (type === 'association') {
    if (policy.associationArtifact && !isArtifactLike(source) && !isArtifactLike(target)) return 'block_association'
    return null
  }
  if (isArtifactLike(source) || isArtifactLike(target)) return policy.noSequenceOnArtifacts ? 'block_artifact_flow' : null
  if (type === 'message_flow') {
    if (policy.messageFlowParticipants && participantOf(doc, source) === participantOf(doc, target)) return 'block_message_flow'
    return null
  }
  // A sequence flow stays inside one process; crossing to an external
  // participant is what a message flow is for (BPMN 2.0 §9.3).
  if (policy.messageFlowParticipants && participantOf(doc, source) !== participantOf(doc, target)) return 'block_sequence_participants'
  if (isStart(target)) return 'block_start_target'
  if (isEnd(source)) return 'block_end_source'
  if (policy.oneInOneOut) {
    const flows = (list) => list.filter((e) => edgeType(e) === 'sequence_flow' && !sameId(e.id, ignoreEdgeId))
    if (isActivity(source) && flows(outgoing(doc, source.id)).length > 0) return 'block_connection'
    if (isActivity(target) && flows(incoming(doc, target.id)).length > 0) return 'block_connection'
  }
  return null
}

// The label a new outgoing connection of an exclusive gateway starts with:
// the first is "Yes", the second "No", any further one empty.
export function defaultLabel (doc, source, labels = {}) {
  if (!source || source.type !== 'exclusive_gateway') return ''
  const used = outgoing(doc, source.id).map((e) => String(e.label || '').trim().toLowerCase())
  if (labels.yes && !used.includes(labels.yes.toLowerCase())) return labels.yes
  if (labels.no && !used.includes(labels.no.toLowerCase())) return labels.no
  return ''
}

export function connect (doc, sourceId, targetId, { type = 'sequence_flow', policy = DEFAULT_POLICY, ports, labels = {} } = {}) {
  const error = connectionError(doc, sourceId, targetId, { type, policy })
  if (error) return blocked(error)
  const edge = { id: newId(doc, 'e_'), source: String(sourceId), target: String(targetId) }
  if (type !== 'sequence_flow') edge.type = type
  if (type === 'sequence_flow') {
    const label = defaultLabel(doc, findNode(doc, sourceId), labels)
    if (label) edge.label = label
  }
  if (ports) edge.ports = ports
  return { doc: { ...doc, edges: [...doc.edges, edge] }, id: edge.id }
}

export function reconnect (doc, edgeId, { source, target }, { policy = DEFAULT_POLICY } = {}) {
  const edge = doc.edges.find((e) => sameId(e.id, edgeId))
  if (!edge) return { doc }
  const nextSource = source ?? edge.source
  const nextTarget = target ?? edge.target
  const error = connectionError(doc, nextSource, nextTarget, { type: edgeType(edge), policy, ignoreEdgeId: edge.id })
  if (error) return blocked(error)
  const ports = { ...(edge.ports || {}) }
  if (source != null) ports.source = 'auto'
  if (target != null) ports.target = 'auto'
  return updateEdge(doc, edgeId, { source: String(nextSource), target: String(nextTarget), ports, waypoints: [] })
}

// ── deleting ───────────────────────────────────────────────────────────────

export function deleteElements (doc, { nodeIds = [], edgeIds = [], laneIds = [] }, { policy = DEFAULT_POLICY } = {}) {
  const nodes = new Set(nodeIds.map(String))
  const edges = new Set(edgeIds.map(String))
  const lanes = new Set(laneIds.map(String))
  if (lanes.size) {
    const holds = doc.nodes.some((n) => n.lane_id != null && lanes.has(String(n.lane_id)) && !nodes.has(String(n.id)))
    if (holds) return blocked('block_lane_has_nodes')
    const remaining = doc.lanes.length - lanes.size
    if (policy.minLanes && remaining < policy.minLanes) return blocked('block_min_lanes', { count: policy.minLanes })
  }
  let next = {
    ...doc,
    nodes: doc.nodes.filter((n) => !nodes.has(String(n.id))),
    edges: doc.edges.filter((e) => !edges.has(String(e.id)) && !nodes.has(String(e.source)) && !nodes.has(String(e.target))),
    annotations: (doc.annotations || []).filter((a) => !nodes.has(String(a.target_id)) && !edges.has(String(a.target_id)))
  }
  // Removing a lane closes its gap: the lanes after it move back.
  for (const laneId of lanes) {
    const layout = layoutLanes(next)
    const entry = layout.byId.get(laneId)
    if (!entry) continue
    const later = new Set(layout.entries.filter((e) => e.offset > entry.offset).map((e) => String(e.id)))
    const moved = new Set(next.nodes.filter((n) => n.lane_id != null && later.has(String(n.lane_id))).map((n) => String(n.id)))
    next = {
      ...next,
      lanes: next.lanes.filter((l) => String(l.id) !== laneId),
      nodes: next.nodes.map((n) => (moved.has(String(n.id)) ? shiftNodeMain(n, -entry.size, layout.axis) : n)),
      edges: clearWaypointsOf(next.edges, moved)
    }
  }
  return { doc: next }
}

// ── orientation ────────────────────────────────────────────────────────────

// Flow steps differ by orientation (an activity is wider than tall), so the
// distance along the flow scales by this ratio when the lanes turn.
const FLOW_SCALE = { vertical: 116 / 200, horizontal: 200 / 116 }

export function setOrientation (doc, orientation) {
  const from = orientationOf(doc)
  if (from === orientation) return { doc }
  const oldLayout = layoutLanes(doc)
  const oldAxis = oldLayout.axis
  const newAxis = axisFor(orientation)
  const lanes = doc.lanes.map((l) => {
    const size = laneSize(l, from) * (orientation === 'vertical' ? 4 / 3 : 3 / 4)
    return { ...l, size: Math.ceil(Math.max(MIN_LANE_SIZE[orientation], size) / 10) * 10 }
  })
  const newLayout = layoutLanes({ ...doc, orientation, lanes })
  const nodes = doc.nodes.map((n) => {
    const box = nodeBox(n)
    const center = { x: box.cx, y: box.cy }
    const oldEntry = n.lane_id != null ? oldLayout.byId.get(String(n.lane_id)) : null
    const newEntry = n.lane_id != null ? newLayout.byId.get(String(n.lane_id)) : null
    const along = (center[oldAxis.cross] - HEADER[from]) * FLOW_SCALE[orientation] + HEADER[orientation]
    const across = oldEntry && newEntry
      ? newEntry.offset + ((center[oldAxis.main] - oldEntry.offset) / oldEntry.size) * newEntry.size
      : center[oldAxis.main]
    const next = { ...n }
    next[newAxis.cross] = Math.round(along - (newAxis.cross === 'x' ? box.w : box.h) / 2)
    next[newAxis.main] = Math.round(across - (newAxis.main === 'x' ? box.w : box.h) / 2)
    return next
  })
  const pool = { ...(doc.pool || {}) }
  delete pool.length
  const edges = doc.edges.map((e) => ({ ...e, ports: { source: 'auto', target: 'auto' }, waypoints: [] }))
  return { doc: fitLanes({ ...doc, orientation, lanes, nodes, edges, pool }) }
}

// ── quick edits ────────────────────────────────────────────────────────────

const GAP = { horizontal: 56, vertical: 46 }

// Moves every node whose centre lies at or beyond `from` on the flow axis by
// `by`, except `exceptId` — makes room along the flow.
function shiftAlong (doc, from, by, exceptId) {
  const axis = axisFor(orientationOf(doc))
  const moved = new Set()
  const nodes = doc.nodes.map((n) => {
    if (sameId(n.id, exceptId)) return n
    const box = nodeBox(n)
    const center = axis.cross === 'x' ? box.cx : box.cy
    if (center < from) return n
    moved.add(String(n.id))
    return { ...n, [axis.cross]: (Number(n[axis.cross]) || 0) + by }
  })
  return { ...doc, nodes, edges: clearWaypointsOf(doc.edges, moved) }
}

function growEdgeLane (doc, layout, source, center, size) {
  const main = layout.axis.main
  const first = layout.entries[0]
  const last = layout.entries[layout.entries.length - 1]
  const start = center[main] - size / 2
  const end = center[main] + size / 2
  const grow = (entry, by) => doc.lanes.map((l) => (sameId(l.id, entry.id) ? { ...l, size: entry.size + by } : l))
  if (end > layout.thickness && sameId(source.lane_id, last.id)) {
    return { doc: { ...doc, lanes: grow(last, Math.ceil(end + LANE_PADDING - layout.thickness)) }, center: center[main] }
  }
  if (start < 0 && sameId(source.lane_id, first.id)) {
    const by = Math.ceil(LANE_PADDING - start)
    const nodes = doc.nodes.map((n) => ({ ...n, [main]: (Number(n[main]) || 0) + by }))
    return { doc: { ...doc, lanes: grow(first, by), nodes, edges: clearWaypointsOf(doc.edges, new Set(nodes.map((n) => String(n.id)))) }, center: center[main] + by }
  }
  return null
}

// "Add the next element" from the quick menu: a node of `attrs` placed next
// to `sourceId` in `direction` (up/down/left/right), already connected. When
// the spot ahead along the flow is taken, the following nodes move along;
// otherwise there is no room and the edit is blocked.
export function appendNode (doc, sourceId, attrs, direction, { policy = DEFAULT_POLICY, names = {}, labels = {} } = {}) {
  const source = findNode(doc, sourceId)
  if (!source) return blocked('block_no_space')
  const orientation = orientationOf(doc)
  const axis = axisFor(orientation)
  const probe = { ...attrs, id: '__probe__' }
  const connectError = connectionError({ ...doc, nodes: [...doc.nodes, probe] }, source.id, probe.id, { policy })
  if (connectError) return blocked(connectError)
  const box = nodeBox(source)
  const { width, height } = nodeSize(attrs)
  const gap = GAP[orientation]
  const center = { x: box.cx, y: box.cy }
  if (direction === 'right') center.x = box.x + box.w + gap + width / 2
  if (direction === 'left') center.x = box.x - gap - width / 2
  if (direction === 'down') center.y = box.y + box.h + gap + height / 2
  if (direction === 'up') center.y = box.y - gap - height / 2
  let layout = layoutLanes(doc)
  if (layout.entries.length && !laneAt(layout, center)) {
    // Past the first or last lane's edge, across the flow: that lane grows
    // to take it (lanes fitted to their content leave no spare band).
    const grown = growEdgeLane(doc, layout, source, center, axis.main === 'y' ? height : width)
    if (grown) { doc = grown.doc; center[axis.main] = grown.center; layout = layoutLanes(doc) }
  }
  if (layout.entries.length) {
    const entry = laneAt(layout, center)
    const crossStart = (axis.cross === 'x' ? center.x - width / 2 : center.y - height / 2)
    if (!entry || crossStart < layout.header) return blocked('block_no_space')
    // Into another lane: centre it in that lane's band.
    if (!sameId(entry.id, source.lane_id)) center[axis.main] = entry.offset + entry.size / 2
  }
  const forward = (axis.cross === 'x' && direction === 'right') || (axis.cross === 'y' && direction === 'down')
  let created = createNode(doc, attrs, center, { policy, names })
  if (created.error === 'block_overlap' && forward) {
    const from = (axis.cross === 'x' ? box.x + box.w : box.y + box.h) + 1
    const step = (axis.cross === 'x' ? width : height) + gap
    created = createNode(shiftAlong(doc, from, step, source.id), attrs, center, { policy, names })
  }
  if (created.error) return blocked(created.error === 'block_overlap' || created.error === 'block_lane' ? 'block_no_space' : created.error)
  const connected = connect(created.doc, source.id, created.id, { policy, labels })
  if (connected.error) return connected
  return { doc: connected.doc, id: created.id, edgeId: connected.id }
}

// An activity has one way out (R01/R02), so a second one is a split. What the
// quick menu and a blocked connection offer then: null when `sourceId` is not
// an activity with exactly one outgoing sequence flow; otherwise that flow,
// and the splitting gateway it already leads to (null when it leads
// elsewhere and a gateway has to be inserted).
export function branchPoint (doc, sourceId) {
  const source = findNode(doc, sourceId)
  if (!source || !isActivity(source)) return null
  const out = outgoing(doc, source.id).filter((e) => edgeType(e) === 'sequence_flow')
  if (out.length !== 1) return null
  const next = findNode(doc, out[0].target)
  const splitting = next && categoryOf(next) === CATEGORY.gateway &&
    incoming(doc, next.id).filter((e) => edgeType(e) === 'sequence_flow').length <= 1
  return { edge: out[0], split: splitting ? next : null }
}

// Puts a gateway of type `gateway` after the activity, on its way out, unless
// that way already leads to a splitting gateway: { doc, gatewayId }.
function splitAfter (doc, sourceId, gateway, { policy, names }) {
  const point = branchPoint(doc, sourceId)
  if (!point) return blocked('block_connection')
  if (point.split) return { doc, gatewayId: String(point.split.id), existing: true }
  if (!gateway) return blocked('block_needs_gateway')
  // `gateway`: a gateway type, or the attributes of one (the Yes/No decision).
  const attrs = typeof gateway === 'string' ? { type: gateway } : gateway
  // Right after the activity along the flow, whichever way its target lies.
  const orientation = orientationOf(doc)
  const box = nodeBox(findNode(doc, sourceId))
  const size = nodeSize(attrs)
  const at = axisFor(orientation).cross === 'x'
    ? { x: box.x + box.w + GAP[orientation] + size.width / 2, y: box.cy }
    : { x: box.cx, y: box.y + box.h + GAP[orientation] + size.height / 2 }
  const inserted = insertOnEdge(doc, point.edge.id, attrs, at, { policy, names })
  if (inserted.error) return inserted
  return { doc: inserted.doc, gatewayId: String(inserted.id), existing: false }
}

// The quick menu from an activity that already has its way out: the new
// element becomes a branch — of the splitting gateway that way leads to, or of
// a `gateway` inserted after the activity, the existing way passing through
// it. A new gateway's branches are left unnamed (R03 reports them pending).
export function branchNode (doc, sourceId, attrs, direction, { gateway, policy = DEFAULT_POLICY, names = {}, labels = {} } = {}) {
  const split = splitAfter(doc, sourceId, gateway, { policy, names })
  if (split.error) return split
  const appended = appendNode(split.doc, split.gatewayId, attrs, direction, { policy, names, labels: split.existing ? labels : {} })
  if (appended.error) return appended
  return { ...appended, gatewayId: split.gatewayId }
}

// An activity has one way in, too: a second one — a return for rework, a
// path joining — enters through a merging XOR placed before the activity
// (AFAL COM-22, SEC-05). The XOR the way in already comes from is reused when
// it leads only there. { doc, gatewayId } or a block.
function mergeBefore (doc, targetId, { policy, names }) {
  const target = findNode(doc, targetId)
  const ins = target && isActivity(target) ? incoming(doc, target.id).filter((e) => edgeType(e) === 'sequence_flow') : []
  if (ins.length !== 1) return blocked('block_connection')
  const from = findNode(doc, ins[0].source)
  if (from && from.type === 'exclusive_gateway' && !isBinaryDecision(from) && outgoing(doc, from.id).filter((e) => edgeType(e) === 'sequence_flow').length === 1) {
    return { doc, gatewayId: String(from.id) }
  }
  const box = nodeBox(target)
  const inserted = insertOnEdge(doc, ins[0].id, { type: 'exclusive_gateway' }, { x: box.cx, y: box.cy }, { policy, names })
  if (inserted.error) return inserted
  return { doc: inserted.doc, gatewayId: String(inserted.id) }
}

// What a refused connection needs to become valid: a split after a source
// activity that already has its way out, a merging XOR before a target
// activity that already has its way in, or both. null when neither applies.
export function gatewaysNeeded (doc, sourceId, targetId, { policy = DEFAULT_POLICY } = {}) {
  if (!policy.oneInOneOut) return null
  const flows = (list) => list.filter((e) => edgeType(e) === 'sequence_flow')
  const source = findNode(doc, sourceId)
  const target = findNode(doc, targetId)
  if (!source || !target) return null
  const split = isActivity(source) && flows(outgoing(doc, source.id)).length === 1
  const merge = isActivity(target) && flows(incoming(doc, target.id)).length === 1
  return split || merge ? { split, merge } : null
}

// A connection refused by the one-in, one-out rule, made through the gateways
// it needs instead: the split as in branchNode, the merge as in mergeBefore.
export function connectThroughGateway (doc, sourceId, targetId, { gateway = 'exclusive_gateway', policy = DEFAULT_POLICY, names = {}, labels = {} } = {}) {
  const needed = gatewaysNeeded(doc, sourceId, targetId, { policy })
  if (!needed) return blocked('block_connection')
  let current = doc
  let from = String(sourceId)
  let to = String(targetId)
  let keepLabels = true
  if (needed.split) {
    const split = splitAfter(current, sourceId, gateway, { policy, names })
    if (split.error) return split
    current = split.doc
    from = split.gatewayId
    keepLabels = split.existing
  }
  if (needed.merge) {
    const merge = mergeBefore(current, targetId, { policy, names })
    if (merge.error) return merge
    current = merge.doc
    to = merge.gatewayId
  }
  const connected = connect(current, from, to, { policy, labels: keepLabels ? labels : {} })
  if (connected.error) return connected
  return { ...connected, gatewayId: needed.split ? from : to }
}

// Drops a node onto an existing sequence flow: source → new → target, the
// label and the source port kept on the first half, nothing disconnected.
// The new node goes right after the source along the flow and everything
// further along moves to make room.
export function insertOnEdge (doc, edgeId, attrs, point, { policy = DEFAULT_POLICY, names = {} } = {}) {
  const edge = doc.edges.find((e) => sameId(e.id, edgeId))
  if (!edge || edgeType(edge) !== 'sequence_flow') return blocked('block_connection')
  const source = findNode(doc, edge.source)
  const target = findNode(doc, edge.target)
  if (!source || !target) return blocked('block_connection')
  const orientation = orientationOf(doc)
  const axis = axisFor(orientation)
  const { width, height } = nodeSize(attrs)
  const size = axis.cross === 'x' ? width : height
  const gap = GAP[orientation]
  const sourceBox = nodeBox(source)
  const along = (box) => (axis.cross === 'x' ? box.cx : box.cy)
  const sourceEnd = axis.cross === 'x' ? sourceBox.x + sourceBox.w : sourceBox.y + sourceBox.h
  const ahead = along(nodeBox(target)) > along(sourceBox)
  const center = { ...point }
  if (ahead) center[axis.cross] = sourceEnd + gap + size / 2
  const layout = layoutLanes(doc)
  const dropLane = layout.entries.length ? laneAt(layout, point) : null
  if (!dropLane || sameId(dropLane.id, source.lane_id)) {
    center[axis.main] = axis.main === 'y' ? sourceBox.cy : sourceBox.cx
  }
  const room = ahead ? shiftAlong(doc, sourceEnd + 1, size + gap, source.id) : doc
  const created = createNode(room, attrs, center, { policy, names })
  if (created.error) return created
  const id = String(created.id)
  // Both halves must be connections that could be drawn by hand: no start
  // event in the middle of a flow, no end event with something after it.
  const without = { ...created.doc, edges: created.doc.edges.filter((e) => !sameId(e.id, edge.id)) }
  const error = connectionError(without, edge.source, id, { policy }) ||
    connectionError({ ...without, edges: [...without.edges, { id: '__first__', source: String(edge.source), target: id }] }, id, edge.target, { policy })
  if (error) return blocked(error)
  // The first half keeps the edge's id, so notes pinned to it stay pinned.
  const first = { ...edge, target: id, ports: { source: (edge.ports || {}).source || 'auto', target: 'auto' }, waypoints: [] }
  const second = { id: newId({ ...without, edges: [...without.edges, first] }, 'e_'), source: id, target: String(edge.target), ports: { source: 'auto', target: (edge.ports || {}).target || 'auto' } }
  return { doc: { ...without, edges: [...without.edges, first, second] }, id }
}

// Aligns the selected nodes on one axis (to their average). Across the flow
// ("vertical" for horizontal lanes) they may sit in different lanes; along the
// lane's stacking axis they must share one, or they would change participant.
export function alignNodes (doc, ids, direction, { policy = DEFAULT_POLICY } = {}) {
  const set = new Set(ids.map(String))
  const nodes = doc.nodes.filter((n) => set.has(String(n.id)))
  if (nodes.length < 2) return { doc }
  const axis = axisFor(orientationOf(doc))
  // "vertical" = line them up in a column (same x); "horizontal" = in a row (same y).
  const coordinate = direction === 'vertical' ? 'x' : 'y'
  const acrossLanes = coordinate === axis.main
  if (acrossLanes && doc.lanes.length && new Set(nodes.map((n) => String(n.lane_id))).size > 1) {
    return blocked(direction === 'vertical' ? 'block_align_vertical' : 'block_align_horizontal')
  }
  const center = (n) => (coordinate === 'x' ? nodeBox(n).cx : nodeBox(n).cy)
  const target = Math.round(nodes.reduce((sum, n) => sum + center(n), 0) / nodes.length)
  const next = {
    ...doc,
    nodes: doc.nodes.map((n) => {
      if (!set.has(String(n.id))) return n
      const half = (coordinate === 'x' ? nodeBox(n).w : nodeBox(n).h) / 2
      return { ...n, [coordinate]: Math.round(target - half) }
    }),
    edges: clearWaypointsOf(doc.edges, set)
  }
  if (policy.noOverlap && overlapping(next, set)) return blocked('block_overlap')
  if (policy.insideLane && doc.lanes.length) {
    // Only what the alignment pushes out counts (an imported node already
    // outside is a pending issue, not a reason to refuse).
    const before = layoutLanes(doc)
    const after = layoutLanes(next)
    const wasInside = new Set(doc.nodes.filter((n) => insideLane(before, n)).map((n) => String(n.id)))
    const out = next.nodes.some((n) => set.has(String(n.id)) && isFlowNode(n) && wasInside.has(String(n.id)) && !insideLane(after, n))
    if (out) return blocked('block_lane')
  }
  return { doc: fitLanes(next) }
}

// ── review notes ───────────────────────────────────────────────────────────

// A numbered note pinned to an element, numbered after the highest one, so
// deleting a note in the middle leaves the others' numbers alone.
export function addAnnotation (doc, targetId, { text = '', tag = null } = {}) {
  const annotations = doc.annotations || []
  const number = annotations.reduce((max, a) => Math.max(max, Number(a.number) || 0), 0) + 1
  const note = { id: newId(doc, 'a_'), target_id: String(targetId), number, text, tag }
  return { doc: { ...doc, annotations: [...annotations, note] }, id: note.id }
}

export function updateAnnotation (doc, id, patch) {
  return { doc: { ...doc, annotations: (doc.annotations || []).map((a) => (sameId(a.id, id) ? { ...a, ...patch } : a)) } }
}

export function deleteAnnotation (doc, id) {
  return { doc: { ...doc, annotations: (doc.annotations || []).filter((a) => !sameId(a.id, id)) } }
}
