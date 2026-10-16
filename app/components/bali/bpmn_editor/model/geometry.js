// Geometry of a BPMN document. Every coordinate here is POOL-RELATIVE: a node's
// x/y is its top-left corner measured from the pool origin, so moving the whole
// set of lanes only changes `pool.x/y`.
//
// Lanes stack along the MAIN axis (y for horizontal lanes, x for vertical ones)
// and stretch along the CROSS axis, which is also the direction the flow reads
// in. They share one cross length. Nothing outside AXES branches on the
// orientation.
import { nodeSize, labelExtent } from './catalog.js'

export const AXES = {
  horizontal: { name: 'horizontal', main: 'y', cross: 'x', mainSize: 'height', crossSize: 'width' },
  vertical: { name: 'vertical', main: 'x', cross: 'y', mainSize: 'width', crossSize: 'height' }
}

// Thickness of the lane header on the cross axis: a rotated label on the left
// of a horizontal lane, a two-line title on top of a vertical one.
export const HEADER = { horizontal: 44, vertical: 52 }
export const DEFAULT_LANE_SIZE = { horizontal: 180, vertical: 240 }
export const MIN_LANE_SIZE = { horizontal: 90, vertical: 160 }
export const MIN_POOL_LENGTH = { horizontal: 760, vertical: 560 }
// Room after the furthest node, so there is always somewhere to drop the next one.
export const POOL_TAIL = { horizontal: 160, vertical: 120 }
// Gap a node keeps from its lane's borders.
export const LANE_PADDING = 10

export const axisFor = (orientation) => AXES[orientation] || AXES.horizontal
export const orientationOf = (doc) => (doc && doc.orientation === 'vertical' ? 'vertical' : 'horizontal')
export const poolOrigin = (doc) => ({ x: Number(doc.pool && doc.pool.x) || 0, y: Number(doc.pool && doc.pool.y) || 0 })

export function sortedLanes (doc) {
  return (doc.lanes || [])
    .map((lane, index) => ({ lane, index }))
    .sort((a, b) => (Number(a.lane.order ?? a.index) - Number(b.lane.order ?? b.index)) || a.index - b.index)
    .map(({ lane }) => lane)
}

export function laneSize (lane, orientation) {
  const size = Number(lane.size)
  return size > 0 ? size : DEFAULT_LANE_SIZE[orientation]
}

export function nodeBox (node) {
  const { width, height } = nodeSize(node)
  const x = Number(node.x) || 0
  const y = Number(node.y) || 0
  return { x, y, w: width, h: height, cx: x + width / 2, cy: y + height / 2 }
}

// The box plus the label printed under events and gateways.
export function nodeFootprint (node) {
  const box = nodeBox(node)
  const extra = labelExtent(node)
  if (!extra) return box
  const grow = Math.max(0, 120 - box.w) / 2
  return { ...box, x: box.x - grow, w: box.w + grow * 2, h: box.h + extra }
}

// Everything the canvas needs about the lanes, computed once per document.
export function layoutLanes (doc) {
  const orientation = orientationOf(doc)
  const axis = axisFor(orientation)
  const header = HEADER[orientation]
  let offset = 0
  const entries = sortedLanes(doc).map((lane) => {
    const size = laneSize(lane, orientation)
    const entry = { lane, id: lane.id, offset, size }
    offset += size
    return entry
  })
  let furthest = 0
  for (const node of doc.nodes || []) {
    const box = nodeFootprint(node)
    const end = axis.cross === 'x' ? box.x + box.w : box.y + box.h
    if (end > furthest) furthest = end
  }
  const length = Math.max(
    Number(doc.pool && doc.pool.length) || 0,
    MIN_POOL_LENGTH[orientation],
    Math.ceil((furthest + POOL_TAIL[orientation]) / 10) * 10
  )
  const byId = new Map(entries.map((entry) => [String(entry.id), entry]))
  return { orientation, axis, header, entries, byId, length, thickness: offset }
}

export function laneRect (layout, entry) {
  return layout.axis.main === 'y'
    ? { x: 0, y: entry.offset, w: layout.length, h: entry.size }
    : { x: entry.offset, y: 0, w: entry.size, h: layout.length }
}

export function poolRect (layout) {
  return layout.axis.main === 'y'
    ? { x: 0, y: 0, w: layout.length, h: layout.thickness }
    : { x: 0, y: 0, w: layout.thickness, h: layout.length }
}

// Lane whose band holds the point on the main axis, or null — the header and
// the far end of the cross axis count as inside: the pool grows to fit.
export function laneAt (layout, point) {
  const main = point[layout.axis.main]
  const cross = point[layout.axis.cross]
  if (cross < 0) return null
  return layout.entries.find((entry) => main >= entry.offset && main < entry.offset + entry.size) || null
}

export const centerOf = (box) => ({ x: box.cx ?? box.x + box.w / 2, y: box.cy ?? box.y + box.h / 2 })

// Whether a node sits fully inside its lane: within the band, clear of the
// header. The cross end is open (the pool length follows the nodes).
export function insideLane (layout, node) {
  const entry = node.lane_id != null ? layout.byId.get(String(node.lane_id)) : null
  if (!entry) return false
  const box = nodeBox(node)
  const { main, cross } = layout.axis
  const mainStart = main === 'y' ? box.y : box.x
  const mainEnd = main === 'y' ? box.y + box.h : box.x + box.w
  const crossStart = cross === 'x' ? box.x : box.y
  return mainStart >= entry.offset && mainEnd <= entry.offset + entry.size && crossStart >= layout.header
}

export function boxesOverlap (a, b, margin = 0) {
  return a.x < b.x + b.w + margin && b.x < a.x + a.w + margin &&
         a.y < b.y + b.h + margin && b.y < a.y + a.h + margin
}

// Bounding box of everything drawn, pool-relative.
export function contentBounds (doc, layout = layoutLanes(doc)) {
  const boxes = (doc.nodes || []).map(nodeFootprint)
  if (layout.entries.length) boxes.push(poolRect(layout))
  if (!boxes.length) return { x: 0, y: 0, w: 0, h: 0 }
  const x = Math.min(...boxes.map((b) => b.x))
  const y = Math.min(...boxes.map((b) => b.y))
  const right = Math.max(...boxes.map((b) => b.x + b.w))
  const bottom = Math.max(...boxes.map((b) => b.y + b.h))
  return { x, y, w: right - x, h: bottom - y }
}

// The size a lane needs on the main axis to hold its nodes (labels included).
export function laneRequiredSize (doc, layout, laneId) {
  const entry = layout.byId.get(String(laneId))
  if (!entry) return 0
  const { main } = layout.axis
  let need = MIN_LANE_SIZE[layout.orientation]
  for (const node of doc.nodes || []) {
    if (String(node.lane_id) !== String(laneId)) continue
    const box = nodeFootprint(node)
    const end = (main === 'y' ? box.y + box.h : box.x + box.w) - entry.offset + LANE_PADDING
    if (end > need) need = end
  }
  return Math.ceil(need / 10) * 10
}
