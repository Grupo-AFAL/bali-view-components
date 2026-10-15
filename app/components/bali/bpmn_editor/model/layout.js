// Auto-layout ("Tidy the flow"): a layered layout that keeps every node in its
// lane, so it works with lanes as well as without them — the reason it is not
// dagre, which knows nothing about lanes.
//
// 1. Layers by longest path from the sources over the sequence flows, back
//    edges (loops) ignored, so the main path reads along the flow axis.
// 2. Inside each layer and lane, nodes are ordered by the barycentre of their
//    predecessors, which keeps branches from crossing.
// 3. Each lane is resized to the most crowded layer it holds.
// Artifacts and data elements keep their place; connections go back to
// automatic routing.
import { isArtifactLike, nodeSize } from './catalog.js'
import { layoutLanes, MIN_LANE_SIZE, HEADER, orientationOf } from './geometry.js'

const STEP = { horizontal: 200, vertical: 116 } // distance between layers on the flow axis
const SLOT = { horizontal: 104, vertical: 190 } // room per node across the flow axis
const MARGIN = { horizontal: 40, vertical: 34 } // gap after the lane header
const COLUMN = { horizontal: 150, vertical: 64 } // an activity's extent on the flow axis

function layers (nodes, edges) {
  const ids = nodes.map((n) => String(n.id))
  const known = new Set(ids)
  const out = new Map(ids.map((id) => [id, []]))
  for (const e of edges) {
    if (known.has(String(e.source)) && known.has(String(e.target))) out.get(String(e.source)).push(String(e.target))
  }
  // DFS to find back edges, from nodes without incoming flow first.
  const incoming = new Map(ids.map((id) => [id, 0]))
  for (const [, targets] of out) for (const t of targets) incoming.set(t, incoming.get(t) + 1)
  const roots = ids.filter((id) => incoming.get(id) === 0)
  const state = new Map()
  const back = new Set()
  const visit = (id) => {
    const stack = [[id, 0]]
    state.set(id, 1)
    while (stack.length) {
      const top = stack[stack.length - 1]
      const targets = out.get(top[0])
      if (top[1] < targets.length) {
        const next = targets[top[1]++]
        if (state.get(next) === 1) back.add(`${top[0]}>${next}`)
        else if (!state.get(next)) { state.set(next, 1); stack.push([next, 0]) }
      } else {
        state.set(top[0], 2)
        stack.pop()
      }
    }
  }
  for (const id of [...roots, ...ids]) if (!state.get(id)) visit(id)

  // Longest path over the acyclic remainder (Kahn order).
  const indegree = new Map(ids.map((id) => [id, 0]))
  for (const [source, targets] of out) for (const t of targets) if (!back.has(`${source}>${t}`)) indegree.set(t, indegree.get(t) + 1)
  const layer = new Map(ids.map((id) => [id, 0]))
  const queue = ids.filter((id) => indegree.get(id) === 0)
  while (queue.length) {
    const id = queue.shift()
    for (const t of out.get(id)) {
      if (back.has(`${id}>${t}`)) continue
      layer.set(t, Math.max(layer.get(t), layer.get(id) + 1))
      indegree.set(t, indegree.get(t) - 1)
      if (indegree.get(t) === 0) queue.push(t)
    }
  }
  const predecessors = new Map(ids.map((id) => [id, []]))
  for (const [source, targets] of out) for (const t of targets) if (!back.has(`${source}>${t}`)) predecessors.get(t).push(source)
  return { layer, predecessors }
}

export function autoLayout (doc) {
  const orientation = orientationOf(doc)
  const lanesLayout = layoutLanes(doc)
  const vertical = orientation === 'vertical'
  const flowNodes = (doc.nodes || []).filter((n) => !isArtifactLike(n))
  const { layer, predecessors } = layers(flowNodes, (doc.edges || []).filter((e) => !e.type || e.type === 'sequence_flow'))
  const laneIds = lanesLayout.entries.map((e) => String(e.id))
  const laneOf = (node) => {
    const id = node.lane_id != null ? String(node.lane_id) : null
    return id && laneIds.includes(id) ? id : (laneIds[0] || '')
  }

  // Buckets: lane → layer → nodes, ordered by barycentre of predecessors.
  const slotOf = new Map()
  const buckets = new Map()
  const byLayer = [...flowNodes].sort((a, b) => layer.get(String(a.id)) - layer.get(String(b.id)))
  for (const node of byLayer) {
    const id = String(node.id)
    const key = `${laneOf(node)}|${layer.get(id)}`
    if (!buckets.has(key)) buckets.set(key, [])
    buckets.get(key).push(node)
  }
  const maxLayer = Math.max(0, ...[...layer.values()])
  for (let l = 0; l <= maxLayer; l++) {
    for (const laneId of laneIds.length ? laneIds : ['']) {
      const bucket = buckets.get(`${laneId}|${l}`)
      if (!bucket) continue
      const bary = (node) => {
        const preds = predecessors.get(String(node.id)).filter((p) => slotOf.has(p))
        if (!preds.length) return Number.MAX_SAFE_INTEGER
        return preds.reduce((sum, p) => sum + slotOf.get(p), 0) / preds.length
      }
      bucket.sort((a, b) => bary(a) - bary(b))
      // Free slots go to the nodes whose barycentre is closest.
      const taken = new Set()
      for (const node of bucket) {
        const want = bary(node)
        let slot = want === Number.MAX_SAFE_INTEGER ? 0 : Math.round(want)
        while (taken.has(slot)) slot++
        taken.add(slot)
        slotOf.set(String(node.id), slot)
      }
    }
  }

  // Lane thickness: enough slots for the most crowded layer it holds.
  const slotsPerLane = new Map()
  for (const node of flowNodes) {
    const lane = laneOf(node)
    slotsPerLane.set(lane, Math.max(slotsPerLane.get(lane) || 0, slotOf.get(String(node.id)) + 1))
  }
  let offset = 0
  const laneOffset = new Map()
  const lanes = (doc.lanes || []).map((lane) => ({ ...lane }))
  for (const entry of lanesLayout.entries) {
    const slots = Math.max(1, slotsPerLane.get(String(entry.id)) || 1)
    const size = Math.max(MIN_LANE_SIZE[orientation], slots * SLOT[orientation] + 16)
    laneOffset.set(String(entry.id), offset)
    const lane = lanes.find((l) => String(l.id) === String(entry.id))
    if (lane) lane.size = Math.ceil(size / 10) * 10
    offset += Math.ceil(size / 10) * 10
  }

  const header = laneIds.length ? HEADER[orientation] : 0
  const nodes = (doc.nodes || []).map((node) => {
    const id = String(node.id)
    if (!layer.has(id)) return node
    const { width, height } = nodeSize(node)
    const center = header + MARGIN[orientation] + COLUMN[orientation] / 2 + layer.get(id) * STEP[orientation]
    const along = center - (vertical ? height : width) / 2
    const laneStart = laneOffset.get(laneOf(node)) || 0
    const across = laneStart + 8 + slotOf.get(id) * SLOT[orientation] + (SLOT[orientation] - (vertical ? width : height)) / 2
    const next = { ...node, lane_id: laneIds.length ? laneOf(node) : node.lane_id }
    if (vertical) { next.x = Math.round(across); next.y = Math.round(along) } else { next.x = Math.round(along); next.y = Math.round(across) }
    return next
  })
  // An artifact that arrived without a position goes next to whatever it is
  // associated with, on the far side of the lane from the flow.
  const placed = new Map(nodes.map((n) => [String(n.id), n]))
  for (let i = 0; i < nodes.length; i++) {
    const node = nodes[i]
    if (!isArtifactLike(node) || (node.x != null && node.y != null)) continue
    const link = (doc.edges || []).find((e) => String(e.source) === String(node.id) || String(e.target) === String(node.id))
    const partner = link && placed.get(String(String(link.source) === String(node.id) ? link.target : link.source))
    const { width, height } = nodeSize(node)
    if (partner && partner.x != null) {
      const size = nodeSize(partner)
      nodes[i] = vertical
        ? { ...node, x: partner.x + size.width + 30, y: partner.y + (size.height - height) / 2, lane_id: partner.lane_id }
        : { ...node, x: partner.x + (size.width - width) / 2, y: partner.y - height - 24, lane_id: partner.lane_id }
    } else {
      nodes[i] = { ...node, x: header + 20, y: header + 20 }
    }
  }
  const edges = (doc.edges || []).map((e) => ({ ...e, ports: { source: 'auto', target: 'auto' }, waypoints: [] }))
  const pool = { ...(doc.pool || {}) }
  delete pool.length
  return { ...doc, lanes, nodes, edges, pool }
}

// Whether the document arrived without a position for some flow node — the
// island lays such a document out once, on load.
export const needsLayout = (doc) => (doc.nodes || []).some((n) => !isArtifactLike(n) && (n.x == null || n.y == null))
