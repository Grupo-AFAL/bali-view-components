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
import { nodeSize, isActivity, isArtifactLike, isStart, isEnd, edgeType, categoryOf, CATEGORY } from './catalog.js'
import {
  layoutLanes, laneAt, nodeBox, boxesOverlap, laneRequiredSize, axisFor, sortedLanes, laneSize,
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
    next = {
      ...next,
      lanes: next.lanes.filter((l) => String(l.id) !== laneId),
      nodes: next.nodes.map((n) => (n.lane_id != null && later.has(String(n.lane_id)) ? shiftNodeMain(n, -entry.size, layout.axis) : n))
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
