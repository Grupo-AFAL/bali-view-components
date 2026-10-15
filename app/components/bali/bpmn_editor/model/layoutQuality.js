// How clean a laid-out diagram is, measured on the document itself — what
// the property tests and the reference fixtures assert, and what auto-arrange
// must keep at zero.
//
// HARD (must be 0 after any operation): nodes on top of each other, flow
// nodes outside their lane or on its header, connections through a node, a
// node's name or a pending badge, two connections sharing a stretch of line,
// labels on top of labels, lines or nodes, a badge on a label.
//
// SOFT (kept low, reported): crossings, bends per connection, how far the
// happy path strays from a straight line.
import { isFlowNode, edgeType } from './catalog.js'
import { layoutLanes, insideLane, nodeBox, boxesOverlap } from './geometry.js'
import { nodeLabelBox, badgeBox } from './labels.js'
import { routeAll } from './routing.js'
import { placeEdgeLabels } from './edgeLabels.js'

const EPS = 0.5

// Segment strictly inside a box (touching the border does not count).
export function segmentCrossesBox (p, q, r, shrink = 1) {
  const b = { x: r.x + shrink, y: r.y + shrink, w: r.w - shrink * 2, h: r.h - shrink * 2 }
  if (b.w <= 0 || b.h <= 0) return false
  if (Math.abs(p.x - q.x) < EPS) {
    const y1 = Math.min(p.y, q.y)
    const y2 = Math.max(p.y, q.y)
    return p.x > b.x && p.x < b.x + b.w && y2 > b.y && y1 < b.y + b.h
  }
  const x1 = Math.min(p.x, q.x)
  const x2 = Math.max(p.x, q.x)
  return p.y > b.y && p.y < b.y + b.h && x2 > b.x && x1 < b.x + b.w
}

const segments = (points) => points.slice(1).map((q, i) => [points[i], q])
const horizontal = ([p, q]) => Math.abs(p.y - q.y) < EPS && Math.abs(p.x - q.x) >= EPS
const vertical = ([p, q]) => Math.abs(p.x - q.x) < EPS && Math.abs(p.y - q.y) >= EPS

// Length two collinear segments share (0 when they only touch).
export function sharedLength (a, b) {
  if (horizontal(a) && horizontal(b) && Math.abs(a[0].y - b[0].y) < EPS) {
    const lo = Math.max(Math.min(a[0].x, a[1].x), Math.min(b[0].x, b[1].x))
    const hi = Math.min(Math.max(a[0].x, a[1].x), Math.max(b[0].x, b[1].x))
    return Math.max(0, hi - lo)
  }
  if (vertical(a) && vertical(b) && Math.abs(a[0].x - b[0].x) < EPS) {
    const lo = Math.max(Math.min(a[0].y, a[1].y), Math.min(b[0].y, b[1].y))
    const hi = Math.min(Math.max(a[0].y, a[1].y), Math.max(b[0].y, b[1].y))
    return Math.max(0, hi - lo)
  }
  return 0
}

// A proper crossing: one horizontal and one vertical segment meeting inside both.
export function segmentsCross (a, b) {
  const [h, v] = horizontal(a) && vertical(b) ? [a, b] : vertical(a) && horizontal(b) ? [b, a] : [null, null]
  if (!h) return false
  const x = v[0].x
  const y = h[0].y
  return x > Math.min(h[0].x, h[1].x) + EPS && x < Math.max(h[0].x, h[1].x) - EPS &&
         y > Math.min(v[0].y, v[1].y) + EPS && y < Math.max(v[0].y, v[1].y) - EPS
}

// The main path: from the first start event, always to the successor with
// the longest way still ahead (Method and Style's "happy path").
export function happyPath (doc) {
  const flows = (doc.edges || []).filter((e) => edgeType(e) === 'sequence_flow')
  const out = new Map()
  for (const e of flows) {
    if (!out.has(String(e.source))) out.set(String(e.source), [])
    out.get(String(e.source)).push(String(e.target))
  }
  const depth = new Map()
  const depthOf = (id, seen = new Set()) => {
    if (depth.has(id)) return depth.get(id)
    if (seen.has(id)) return 0
    seen.add(id)
    const d = 1 + Math.max(0, ...(out.get(id) || []).map((t) => depthOf(t, seen)))
    depth.set(id, d)
    return d
  }
  const start = (doc.nodes || []).find((n) => n.type === 'start_event')
  if (!start) return []
  const path = [String(start.id)]
  const visited = new Set(path)
  let current = String(start.id)
  for (;;) {
    const next = (out.get(current) || []).filter((t) => !visited.has(t)).sort((a, b) => depthOf(b) - depthOf(a))[0]
    if (!next) break
    path.push(next)
    visited.add(next)
    current = next
  }
  return path
}

export function measure (doc, { routes = routeAll(doc), edgeLabels = placeEdgeLabels(doc, routes) } = {}) {
  const layout = layoutLanes(doc)
  const orientation = layout.orientation
  const nodes = (doc.nodes || []).filter((n) => n.type !== 'group')
  const boxes = new Map(nodes.map((n) => [String(n.id), nodeBox(n)]))
  const nodeLabels = new Map(nodes.map((n) => [String(n.id), nodeLabelBox(n, orientation)]).filter(([, b]) => b))
  const badges = new Map(nodes.filter(isFlowNode).map((n) => [String(n.id), badgeBox(n)]))
  const details = []
  const result = {
    overlaps: 0,
    outsideLane: 0,
    edgeThroughNode: 0,
    edgeThroughLabel: 0,
    sharedSegments: 0,
    labelOverlaps: 0,
    badgeOnLabel: 0,
    crossings: 0,
    maxBends: 0,
    avgBends: 0,
    happyPathDeviation: 0
  }

  for (let i = 0; i < nodes.length; i++) {
    for (let j = i + 1; j < nodes.length; j++) {
      if (boxesOverlap(boxes.get(String(nodes[i].id)), boxes.get(String(nodes[j].id)), -1)) {
        result.overlaps++
        details.push(['overlap', nodes[i].id, nodes[j].id])
      }
    }
  }
  if (layout.entries.length) {
    for (const n of nodes) {
      if (isFlowNode(n) && !insideLane(layout, n)) { result.outsideLane++; details.push(['outsideLane', n.id]) }
    }
  }

  const routed = (doc.edges || []).map((e) => ({ edge: e, route: routes.get(String(e.id)) })).filter((r) => r.route)
  let bends = 0
  for (const { edge, route } of routed) {
    const segs = segments(route.points)
    const ends = new Set([String(edge.source), String(edge.target)])
    for (const [id, box] of boxes) {
      if (ends.has(id)) {
        // Its own ends: only the first and last stretch may touch them.
        if (segs.slice(1, -1).some((s) => segmentCrossesBox(s[0], s[1], box))) { result.edgeThroughNode++; details.push(['edgeThroughOwnNode', edge.id, id]) }
        continue
      }
      if (segs.some((s) => segmentCrossesBox(s[0], s[1], box))) { result.edgeThroughNode++; details.push(['edgeThroughNode', edge.id, id]) }
    }
    for (const [id, box] of nodeLabels) {
      if (segs.some((s) => segmentCrossesBox(s[0], s[1], box))) { result.edgeThroughLabel++; details.push(['edgeThroughLabel', edge.id, id]) }
    }
    for (const [id, box] of badges) {
      if (ends.has(id) && segs.length <= 2) continue
      if (segs.slice(ends.has(id) ? 1 : 0, ends.has(id) ? -1 : undefined).some((s) => segmentCrossesBox(s[0], s[1], box))) {
        result.edgeThroughLabel++; details.push(['edgeThroughBadge', edge.id, id])
      }
    }
    const b = Math.max(0, route.points.length - 2)
    bends += b
    result.maxBends = Math.max(result.maxBends, b)
  }
  result.avgBends = routed.length ? Math.round((bends / routed.length) * 100) / 100 : 0

  for (let i = 0; i < routed.length; i++) {
    const a = segments(routed[i].route.points)
    for (let j = i + 1; j < routed.length; j++) {
      const b = segments(routed[j].route.points)
      let shared = 0
      let crossing = 0
      for (const s of a) {
        for (const t of b) {
          shared += sharedLength(s, t)
          if (segmentsCross(s, t)) crossing++
        }
      }
      if (shared > 1) { result.sharedSegments++; details.push(['shared', routed[i].edge.id, routed[j].edge.id, Math.round(shared)]) }
      result.crossings += crossing
    }
  }

  // Labels: connection labels against each other, node names, nodes, lines;
  // node names against nodes and each other; badges against any label.
  const allLabels = [
    ...[...nodeLabels].map(([id, box]) => ({ kind: 'node', id, box })),
    ...[...edgeLabels].map(([id, box]) => ({ kind: 'edge', id, box }))
  ]
  for (let i = 0; i < allLabels.length; i++) {
    for (let j = i + 1; j < allLabels.length; j++) {
      if (boxesOverlap(allLabels[i].box, allLabels[j].box, -1)) { result.labelOverlaps++; details.push(['labelOnLabel', allLabels[i].id, allLabels[j].id]) }
    }
    for (const [id, box] of boxes) {
      if (allLabels[i].kind === 'node' && allLabels[i].id === id) continue
      if (boxesOverlap(allLabels[i].box, box, -1)) { result.labelOverlaps++; details.push(['labelOnNode', allLabels[i].id, id]) }
    }
    for (const [id, badge] of badges) {
      if (boxesOverlap(allLabels[i].box, badge, -1)) { result.badgeOnLabel++; details.push(['badgeOnLabel', allLabels[i].id, id]) }
    }
  }
  for (const [id, box] of edgeLabels) {
    for (const { edge, route } of routed) {
      if (segments(route.points).some((s) => segmentCrossesBox(s[0], s[1], box, 0.5))) {
        result.labelOverlaps++
        details.push(['labelOnLine', id, edge.id])
      }
    }
  }

  // Happy path: steps that go back against the reading direction, or move
  // across the flow while staying in the same lane.
  const path = happyPath(doc).map((id) => (doc.nodes || []).find((n) => String(n.id) === id)).filter(Boolean)
  const { main, cross } = layout.axis
  for (let i = 1; i < path.length; i++) {
    const a = nodeBox(path[i - 1])
    const b = nodeBox(path[i])
    const along = (box) => (cross === 'x' ? box.cx : box.cy)
    const across = (box) => (main === 'y' ? box.cy : box.cx)
    if (along(b) <= along(a)) result.happyPathDeviation++
    else if (String(path[i - 1].lane_id) === String(path[i].lane_id) && Math.abs(across(a) - across(b)) > 2) result.happyPathDeviation++
  }

  result.hard = result.overlaps + result.outsideLane + result.edgeThroughNode + result.edgeThroughLabel +
    result.sharedSegments + result.labelOverlaps + result.badgeOnLabel
  result.details = details
  return result
}
