// Auto-arrange ("Tidy the flow"): a complete layered layout that keeps every
// element in its lane — the reason it is not dagre, which knows no lanes.
//
// 1. Columns by longest path from the sources over the sequence flows (loops
//    ignored): one column per rank, aligned across every lane.
// 2. Rows inside each lane: the happy path — from each element, the successor
//    with the longest way still ahead — stays on its row, so it reads as a
//    straight line (Method and Style). Exception branches leave below, then
//    above; the branches of a parallel or inclusive split that merge again sit
//    symmetrically around the split.
// 3. Uniform spacing per column and per row on a 10 px grid; each lane is as
//    thick as its rows.
// 4. Artifacts go next to what they are associated with; then the incremental
//    arrangement settles anything still touching, and every connection is
//    routed again.
import { isArtifactLike, isGateway, nodeSize, edgeType } from './catalog.js'
import { layoutLanes, HEADER, orientationOf } from './geometry.js'
import { arrange, HEADER_GAP, LANE_PAD } from './arrange.js'

const STEP = { horizontal: 230, vertical: 150 } // column to column, along the flow
const SLOT = { horizontal: 120, vertical: 220 } // row to row, across the flow
const COLUMN = { horizontal: 150, vertical: 64 } // an activity's extent along the flow
const ROW = { horizontal: 64, vertical: 150 } // an activity's extent across the flow

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
  return { layer, predecessors, out, back }
}

export function autoLayout (doc) {
  const orientation = orientationOf(doc)
  const lanesLayout = layoutLanes(doc)
  const vertical = orientation === 'vertical'
  const flowNodes = (doc.nodes || []).filter((n) => !isArtifactLike(n))
  const flows = (doc.edges || []).filter((e) => edgeType(e) === 'sequence_flow')
  const { layer, out, back } = layers(flowNodes, flows)
  const byId = new Map(flowNodes.map((n) => [String(n.id), n]))
  const laneIds = lanesLayout.entries.map((e) => String(e.id))
  const laneOf = (id) => {
    const node = byId.get(id)
    const lane = node && node.lane_id != null ? String(node.lane_id) : null
    return lane && laneIds.includes(lane) ? lane : (laneIds[0] || '')
  }
  const forward = (id) => (out.get(id) || []).filter((t) => !back.has(`${id}>${t}`))

  // How long the way ahead is from each element: the happy path follows it.
  const depth = new Map()
  const depthOf = (id) => {
    if (depth.has(id)) return depth.get(id)
    depth.set(id, 0)
    const d = 1 + Math.max(0, ...forward(id).map(depthOf))
    depth.set(id, d)
    return d
  }
  const inCount = new Map()
  for (const [, targets] of out) for (const t of targets) inCount.set(t, (inCount.get(t) || 0) + 1)

  // Rows, walking the columns in order. The first row an element is given is kept.
  const row = new Map()
  const taken = new Set() // lane|layer|row
  const claim = (id, wanted) => {
    const lane = laneOf(id)
    let r = wanted
    for (let k = 1; taken.has(`${lane}|${layer.get(id)}|${r}`); k++) r = wanted + (k % 2 ? Math.ceil(k / 2) : -Math.ceil(k / 2))
    row.set(id, r)
    taken.add(`${lane}|${layer.get(id)}|${r}`)
  }
  const order = [...flowNodes].map((n) => String(n.id)).sort((a, b) => (layer.get(a) - layer.get(b)) || ((inCount.get(a) || 0) - (inCount.get(b) || 0)))
  for (const id of order) {
    if (!row.has(id)) claim(id, 0)
    const here = row.get(id)
    const next = forward(id).filter((t) => !row.has(t)).sort((a, b) => depthOf(b) - depthOf(a))
    if (!next.length) continue
    const node = byId.get(id)
    // A split whose branches merge again (parallel, inclusive): symmetric.
    const symmetric = isGateway(node) && node.type !== 'exclusive_gateway' && next.length > 1
    if (symmetric) {
      const offsets = (next.length % 2 ? [0] : []).concat(...Array.from({ length: Math.ceil(next.length / 2) }, (_, i) => [-(i + 1), i + 1])).slice(0, next.length)
      if (next.length % 2 === 0) offsets.sort((a, b) => a - b)
      next.forEach((t, i) => claim(t, laneOf(t) === laneOf(id) ? here + offsets[i] : offsets[i]))
      continue
    }
    // Rows are counted per lane: when the longest way ahead leaves the lane,
    // the continuation that stays in it keeps the row and leaves the gateway
    // in a straight line; exceptions go below, then above.
    const exception = (i) => (i === 0 ? 0 : i % 2 ? Math.ceil(i / 2) : -Math.ceil(i / 2))
    const sameLane = next.filter((t) => laneOf(t) === laneOf(id))
    const otherLanes = next.filter((t) => laneOf(t) !== laneOf(id))
    sameLane.forEach((t, i) => claim(t, here + exception(i)))
    otherLanes.forEach((t, i) => claim(t, exception(i)))
  }

  // Lane thickness from the rows each lane uses.
  const rowsOf = new Map()
  for (const [id, r] of row) {
    const lane = laneOf(id)
    const [lo, hi] = rowsOf.get(lane) || [r, r]
    rowsOf.set(lane, [Math.min(lo, r), Math.max(hi, r)])
  }
  let offset = 0
  const laneStart = new Map()
  const lanes = (doc.lanes || []).map((lane) => ({ ...lane }))
  for (const entry of lanesLayout.entries) {
    const [lo, hi] = rowsOf.get(String(entry.id)) || [0, 0]
    const size = Math.ceil(((hi - lo + 1) * SLOT[orientation] + LANE_PAD * 2) / 10) * 10
    laneStart.set(String(entry.id), offset)
    const lane = lanes.find((l) => String(l.id) === String(entry.id))
    if (lane) lane.size = size
    offset += size
  }

  const header = laneIds.length ? HEADER[orientation] : 0
  const nodes = (doc.nodes || []).map((node) => {
    const id = String(node.id)
    if (!row.has(id)) return node
    const { width, height } = nodeSize(node)
    const lane = laneOf(id)
    const [lo] = rowsOf.get(lane) || [0, 0]
    const center = header + HEADER_GAP + COLUMN[orientation] / 2 + layer.get(id) * STEP[orientation]
    const across = (laneStart.get(lane) || 0) + LANE_PAD + (row.get(id) - lo) * SLOT[orientation] + ROW[orientation] / 2
    const next = { ...node, lane_id: laneIds.length ? lane : node.lane_id }
    const snap = (v) => Math.round(v / 10) * 10
    if (vertical) { next.x = snap(across) - width / 2; next.y = snap(center) - height / 2 } else { next.x = snap(center) - width / 2; next.y = snap(across) - height / 2 }
    return next
  })

  // Artifacts beside what they are associated with: an annotation above it,
  // a data element below it; with no association, before the first column.
  const placed = new Map(nodes.map((n) => [String(n.id), n]))
  for (let i = 0; i < nodes.length; i++) {
    const node = nodes[i]
    if (!isArtifactLike(node) || node.type === 'group') continue
    const link = (doc.edges || []).find((e) => String(e.source) === String(node.id) || String(e.target) === String(node.id))
    const partner = link && placed.get(String(String(link.source) === String(node.id) ? link.target : link.source))
    const { width, height } = nodeSize(node)
    if (partner && !isArtifactLike(partner)) {
      const p = nodeSize(partner)
      const above = node.type === 'text_annotation'
      nodes[i] = vertical
        ? { ...node, x: partner.x + p.width + 40, y: partner.y + (p.height - height) / 2, lane_id: partner.lane_id }
        : { ...node, x: partner.x + (p.width - width) / 2, y: above ? partner.y - height - 40 : partner.y + p.height + 50, lane_id: partner.lane_id }
    } else if (node.x == null || node.y == null) {
      nodes[i] = { ...node, x: header + 20, y: 20 }
    }
  }
  const edges = (doc.edges || []).map((e) => ({ ...e, ports: { source: 'auto', target: 'auto' }, waypoints: [] }))
  const pool = { ...(doc.pool || {}) }
  delete pool.length
  return arrange({ ...doc, lanes, nodes, edges, pool })
}

// Whether the document arrived without a position for some flow node — the
// island lays such a document out once, on load.
export const needsLayout = (doc) => (doc.nodes || []).some((n) => !isArtifactLike(n) && (n.x == null || n.y == null))
