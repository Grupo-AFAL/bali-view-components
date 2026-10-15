// Incremental arrangement, run after every edit that changes the structure
// while "Auto-arrange" is on. It keeps what the user placed where they placed
// it and only fixes what collides:
//
// - Every element owns a footprint: its shape, its name and its pending badge.
// - Walking along the flow, an element whose footprint runs into one already
//   placed in the same row moves FORWARD along the flow until it is clear —
//   and so do the ones after it, one collision at a time.
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

const snap = (v) => Math.round(v / GRID) * GRID

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
export function arrange (doc) {
  let current = place(doc)
  for (let round = 0; round < 8; round++) {
    const failed = [...routeDiagram(current).entries()].filter(([, r]) => r.failed).map(([id]) => id)
    if (!failed.length) return current
    current = place(makeRoom(current, failed))
  }
  return current
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

function place (doc) {
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
    return {
      node: n,
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
    it.cross = snap(it.cross)
    it.main = snap(it.main)
    for (let guard = 0; guard < 500; guard++) {
      const hit = placed.find((p) => rangeOverlap(start(it, 'main'), end(it, 'main'), start(p, 'main'), end(p, 'main'), GAP_ACROSS / 2) &&
        rangeOverlap(start(it, 'cross'), end(it, 'cross'), start(p, 'cross'), end(p, 'cross'), GAP_ALONG / 2))
      if (!hit) break
      it.cross = snap(end(hit, 'cross') + GAP_ALONG - it.fp[crossD] + GRID / 2)
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
