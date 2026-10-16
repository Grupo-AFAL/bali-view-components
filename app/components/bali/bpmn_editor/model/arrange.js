// The local arrangement, run after every edit that changes the structure. It
// keeps what the user placed where they placed it and only fixes what
// collides or what a deletion emptied:
//
// - Every element owns a footprint: its shape, its name and its pending badge.
// - Walking along the flow, an element whose footprint runs into one already
//   placed in the same row moves FORWARD along the flow until it is clear —
//   and so do the ones after it, one collision at a time.
// - A deletion that leaves a stretch of the flow axis empty in every lane,
//   wider than a column, closes it: what lies beyond moves back, all lanes
//   together, so the arrangement before the gap and across lanes is kept.
// - Flow elements stay clear of the lane header.
// - Each lane then fits its content, growing or shrinking, with the lanes
//   after it moving along, and the shared length follows the content (no
//   long empty tail).
// - Positions snap to a 10 px grid (Method and Style's uniform spacing).
//
// Pure and idempotent: arranging an arranged document returns it unchanged
// (same object), so an edit and its arrangement are one undo step.
import { isFlowNode, isArtifactLike } from './catalog.js'
import { layoutLanes, nodeBox, MIN_LANE_SIZE, orientationOf } from './geometry.js'
import { nodeLabelBox, badgeBox } from './labels.js'
import { routeDiagram } from './router.js'

export const GRID = 10
export const GAP_ALONG = 80 // between neighbours on the flow axis: two port stubs and two channels
export const GAP_ACROSS = 30 // between rows
export const LANE_PAD = 20
export const HEADER_GAP = 40
// Column to column along the flow in "Tidy up" (layout.js) — and the widest
// empty stretch a deletion may leave.
export const STEP = { horizontal: 230, vertical: 150 }

const snap = (v) => Math.round(v / GRID) * GRID
const snapCenter = (start, size) => snap(start + size / 2) - size / 2

// Shape ∪ name ∪ badge, as an offset box relative to the node's x/y.
export function footprint (node, orientation) {
  const box = nodeBox(node)
  const parts = [box]
  const label = nodeLabelBox(node, orientation)
  if (label) parts.push(label)
  if (isFlowNode(node)) parts.push(badgeBox(node))
  const x1 = Math.min(...parts.map((p) => p.x))
  const y1 = Math.min(...parts.map((p) => p.y))
  const x2 = Math.max(...parts.map((p) => p.x + p.w))
  const y2 = Math.max(...parts.map((p) => p.y + p.h))
  return { dx: x1 - box.x, dy: y1 - box.y, w: x2 - x1, h: y2 - y1 }
}

const rangeOverlap = (a1, a2, b1, b2, margin) => a1 < b2 + margin && b1 < a2 + margin

// Arranges, then routes: a connection the router could not lay without
// crossing a node or sharing a line means its corridor is too tight, so the
// elements from its far end on move along the flow and it routes again.
// `before`: the document the edit started from; elements it had and `doc`
// lacks were deleted, and the gap they leave is closed.
// `keep`: ids the user just placed by hand to the pixel (arrow keys with
// Shift) — they are not snapped to the grid, only moved if they collide.
export function arrange (doc, { before = null, keep = null } = {}) {
  let current = place(before ? closeGaps(before, doc) : doc, keep)
  for (let round = 0; round < 8; round++) {
    const failed = [...routeDiagram(current).entries()].filter(([, r]) => r.failed).map(([id]) => id)
    if (!failed.length) return current
    current = place(makeRoom(current, failed), keep)
  }
  return current
}

// Stretches of the flow axis no element covers, between the first element
// and the last, wider than a column: [{ from, to }] in pool coordinates.
export function emptyStretches (doc) {
  const layout = layoutLanes(doc)
  const orientation = layout.orientation
  const { cross } = layout.axis
  const spans = (doc.nodes || []).filter((n) => n.type !== 'group').map((n) => {
    const fp = footprint(n, orientation)
    const start = (Number(n[cross]) || 0) + (cross === 'x' ? fp.dx : fp.dy)
    return [start, start + (cross === 'x' ? fp.w : fp.h)]
  }).sort((a, b) => a[0] - b[0])
  const gaps = []
  let end = spans.length ? spans[0][1] : 0
  for (const [from, to] of spans.slice(1)) {
    if (from - end > STEP[orientation]) gaps.push({ from: end, to: from })
    end = Math.max(end, to)
  }
  return gaps
}

// The empty stretches `doc` has where `before` had an element it no longer
// has: what a deletion left behind.
export function gapsLeftBy (before, doc) {
  const kept = new Set((doc.nodes || []).map((n) => String(n.id)))
  const removed = (before.nodes || []).filter((n) => !kept.has(String(n.id)) && n.type !== 'group')
  if (!removed.length) return []
  const layout = layoutLanes(before)
  const { cross } = layout.axis
  const centers = removed.map((n) => { const b = nodeBox(n); return cross === 'x' ? b.cx : b.cy })
  return emptyStretches(doc).filter((gap) => centers.some((c) => c > gap.from && c < gap.to))
}

function closeGaps (before, doc) {
  const gaps = gapsLeftBy(before, doc)
  if (!gaps.length) return doc
  const { cross } = layoutLanes(doc).axis
  const orientation = orientationOf(doc)
  const startOf = (n) => (Number(n[cross]) || 0) + (cross === 'x' ? footprint(n, orientation).dx : footprint(n, orientation).dy)
  const moved = new Set()
  const nodes = doc.nodes.map((n) => {
    const by = gaps.filter((g) => startOf(n) >= g.to).reduce((sum, g) => sum + snap(g.to - g.from - GAP_ALONG), 0)
    if (!by) return n
    moved.add(String(n.id))
    return { ...n, [cross]: (Number(n[cross]) || 0) - by }
  })
  return { ...doc, nodes, edges: doc.edges.map((e) => (moved.has(String(e.source)) || moved.has(String(e.target))) && e.waypoints && e.waypoints.length ? { ...e, waypoints: [] } : e) }
}

function makeRoom (doc, edgeIds) {
  const layout = layoutLanes(doc)
  const { cross } = layout.axis
  const along = (n) => { const b = nodeBox(n); return cross === 'x' ? b.cx : b.cy }
  let from = Infinity
  for (const id of edgeIds) {
    const edge = doc.edges.find((e) => String(e.id) === id)
    const ends = [edge.source, edge.target].map((nid) => doc.nodes.find((n) => String(n.id) === String(nid))).filter(Boolean)
    if (ends.length === 2) from = Math.min(from, Math.max(...ends.map(along)))
  }
  if (from === Infinity) return doc
  return { ...doc, nodes: doc.nodes.map((n) => (along(n) >= from ? { ...n, [cross]: (Number(n[cross]) || 0) + GAP_ALONG / 2 } : n)) }
}

function place (doc, keep = null) {
  if (!doc.nodes || !doc.nodes.length) return fitLanesToContent(doc)
  const orientation = orientationOf(doc)
  const layout = layoutLanes(doc)
  const { main, cross } = layout.axis
  const header = layout.entries.length ? layout.header : 0
  const crossSize = cross === 'x' ? 'w' : 'h'
  const mainSize = main === 'y' ? 'h' : 'w'
  const crossD = cross === 'x' ? 'dx' : 'dy'
  const mainD = main === 'y' ? 'dy' : 'dx'

  const items = doc.nodes.filter((n) => n.type !== 'group').map((n) => {
    const fp = footprint(n, orientation)
    const box = nodeBox(n)
    return {
      node: n,
      size: { cross: cross === 'x' ? box.w : box.h, main: main === 'y' ? box.h : box.w },
      cross: Number(n[cross]) || 0,
      main: Number(n[main]) || 0,
      fp
    }
  })
  const start = (it, axis) => (axis === 'cross' ? it.cross + it.fp[crossD] : it.main + it.fp[mainD])
  const end = (it, axis) => start(it, axis) + (axis === 'cross' ? it.fp[crossSize] : it.fp[mainSize])
  items.sort((a, b) => (start(a, 'cross') - start(b, 'cross')) || (start(a, 'main') - start(b, 'main')))

  const placed = []
  for (const it of items) {
    // Clear of the header, on the grid.
    // The shape keeps a port stub and its clearance off the header; the name
    // keeps the usual padding.
    if (header && isFlowNode(it.node)) {
      it.cross = Math.max(it.cross, header + HEADER_GAP)
      const minStart = header + LANE_PAD
      if (start(it, 'cross') < minStart) it.cross += minStart - start(it, 'cross')
    }
    // Centres on the grid, not corners: an event, a gateway and a task in one
    // row then share a centre line (their sizes differ).
    if (!keep || !keep.has(String(it.node.id))) {
      it.cross = snapCenter(it.cross, it.size.cross)
      it.main = snapCenter(it.main, it.size.main)
    }
    for (let guard = 0; guard < 500; guard++) {
      const hit = placed.find((p) => rangeOverlap(start(it, 'main'), end(it, 'main'), start(p, 'main'), end(p, 'main'), GAP_ACROSS / 2) &&
        rangeOverlap(start(it, 'cross'), end(it, 'cross'), start(p, 'cross'), end(p, 'cross'), GAP_ALONG / 2))
      if (!hit) break
      it.cross = snapCenter(end(hit, 'cross') + GAP_ALONG - it.fp[crossD] + GRID / 2, it.size.cross)
    }
    placed.push(it)
  }

  let changed = false
  const moved = new Set()
  const byId = new Map(items.map((it) => [String(it.node.id), it]))
  const nodes = doc.nodes.map((n) => {
    const it = byId.get(String(n.id))
    if (!it) return n
    if (it.cross === Number(n[cross]) && it.main === Number(n[main])) return n
    changed = true
    moved.add(String(n.id))
    return { ...n, [cross]: it.cross, [main]: it.main }
  })
  const next = changed
    ? { ...doc, nodes, edges: doc.edges.map((e) => (moved.has(String(e.source)) || moved.has(String(e.target))) && e.waypoints && e.waypoints.length ? { ...e, waypoints: [] } : e) }
    : doc
  return fitLanesToContent(next)
}

// Each lane as thick as its content (footprints plus padding), never under
// the minimum; content that sits far from the top of its lane moves up. The
// lanes after a resized one move along, and the shared length follows the
// content.
export function fitLanesToContent (doc) {
  const layout = layoutLanes(doc)
  if (!layout.entries.length) return dropLength(doc)
  const orientation = layout.orientation
  const { main } = layout.axis
  const mainSize = main === 'y' ? 'h' : 'w'
  const mainD = main === 'y' ? 'dy' : 'dx'
  let offset = 0
  const shiftByNode = new Map()
  const sizes = new Map()
  for (const entry of layout.entries) {
    const inLane = doc.nodes.filter((n) => String(n.lane_id) === String(entry.id) && n.type !== 'group' && !(isArtifactLike(n) && n.lane_id == null))
    let contentStart = null
    let contentEnd = null
    for (const n of inLane) {
      const fp = footprint(n, orientation)
      const s = (Number(n[main]) || 0) + fp[mainD]
      const e = s + fp[mainSize]
      contentStart = contentStart == null ? s : Math.min(contentStart, s)
      contentEnd = contentEnd == null ? e : Math.max(contentEnd, e)
    }
    let inner = 0
    let size = MIN_LANE_SIZE[orientation]
    if (contentStart != null) {
      // Where the content starts inside the lane once fitted: LANE_PAD from the top.
      inner = snap(offset + LANE_PAD - contentStart)
      size = Math.max(size, snap(contentEnd - contentStart + LANE_PAD * 2 + GRID / 2))
    }
    for (const n of inLane) shiftByNode.set(String(n.id), inner)
    sizes.set(String(entry.id), size)
    offset += size
  }
  let changed = false
  const lanes = doc.lanes.map((l) => {
    const size = sizes.get(String(l.id))
    if (size == null || Number(l.size) === size) return l
    changed = true
    return { ...l, size }
  })
  const moved = new Set()
  const nodes = doc.nodes.map((n) => {
    const shift = shiftByNode.get(String(n.id))
    if (!shift) return n
    changed = true
    moved.add(String(n.id))
    return { ...n, [main]: (Number(n[main]) || 0) + shift }
  })
  const next = changed
    ? { ...doc, lanes, nodes, edges: doc.edges.map((e) => (moved.has(String(e.source)) || moved.has(String(e.target))) && e.waypoints && e.waypoints.length ? { ...e, waypoints: [] } : e) }
    : doc
  return dropLength(next)
}

function dropLength (doc) {
  if (!doc.pool || doc.pool.length == null) return doc
  const pool = { ...doc.pool }
  delete pool.length
  return { ...doc, pool }
}
