// Where each connection's label goes (pool-relative boxes), read by the
// canvas, the export and the quality metric alike.
//
// A gateway's branch is named by its condition, so the label sits next to
// where the line leaves the gateway (Camunda's modeling guidelines), beside
// the line and never on it: above a horizontal stretch or to the right of a
// vertical one, sliding along the first stretches until it touches no node,
// name, badge, line or other label. Only when every spot near the source is
// taken does it look further along the line.
import { nodeBox, layoutLanes } from './geometry.js'
import { nodeLabelBox, badgeBox, edgeLabelSize } from './labels.js'
import { categoryOf, CATEGORY } from './catalog.js'

const GAP = 4
const STEP = 8

const overlaps = (a, b) => a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h

function touchesSegment (box, p, q) {
  if (Math.abs(p.x - q.x) < 0.5) {
    return p.x >= box.x && p.x <= box.x + box.w && Math.max(p.y, q.y) >= box.y && Math.min(p.y, q.y) <= box.y + box.h
  }
  return p.y >= box.y && p.y <= box.y + box.h && Math.max(p.x, q.x) >= box.x && Math.min(p.x, q.x) <= box.x + box.w
}

// Candidate boxes beside segment p→q, starting `start` px into it: first
// right beside the line, then one and two label-heights further out — a short
// stretch between close neighbours has no room right beside it. A box may run
// past the end of the stretch; the check against every line keeps it off them.
function * besideSegment (p, q, w, h, start = 6, { reach = 2, past = 0 } = {}) {
  const length = Math.abs(q.x - p.x) + Math.abs(q.y - p.y)
  const horizontal = Math.abs(p.y - q.y) < 0.5
  const sign = horizontal ? Math.sign(q.x - p.x) || 1 : Math.sign(q.y - p.y) || 1
  for (let k = 0; k <= reach; k++) {
    const away = GAP + k * h
    for (let d = start; d <= Math.max(start, length + past); d += STEP) {
      if (horizontal) {
        const x = sign > 0 ? p.x + d : p.x - d - w
        yield { x, y: p.y - away - h, w, h }
        yield { x, y: p.y + away, w, h }
      } else {
        const y = sign > 0 ? p.y + d : p.y - d - h
        yield { x: p.x + away + 2, y, w, h }
        yield { x: p.x - away - 2 - w, y, w, h }
      }
    }
  }
}

export function placeEdgeLabels (doc, routes) {
  const orientation = layoutLanes(doc).orientation
  const nodes = (doc.nodes || []).filter((n) => n.type !== 'group')
  const blocked = []
  for (const n of nodes) {
    blocked.push(nodeBox(n))
    const label = nodeLabelBox(n, orientation)
    if (label) blocked.push(label)
    if (categoryOf(n) !== CATEGORY.artifact && categoryOf(n) !== CATEGORY.data) blocked.push(badgeBox(n))
  }
  const lines = []
  for (const route of routes.values()) {
    for (let i = 0; i < route.points.length - 1; i++) lines.push([route.points[i], route.points[i + 1]])
  }
  const free = (box) => !blocked.some((b) => overlaps(box, b)) && !lines.some(([p, q]) => touchesSegment(box, p, q))

  const placed = new Map()
  for (const edge of doc.edges || []) {
    if (!edge.label) continue
    const route = routes.get(String(edge.id))
    if (!route || route.points.length < 2) continue
    const { w, h } = edgeLabelSize(edge.label)
    let chosen = null
    const segments = route.points.slice(1).map((q, i) => [route.points[i], q])
    for (const [i, [p, q]] of segments.entries()) {
      for (const box of besideSegment(p, q, w, h, i === 0 ? 10 : 4)) {
        if (free(box)) { chosen = box; break }
      }
      if (chosen) break
    }
    // Crowded (a short stretch between close neighbours): further out and
    // past the stretch's end; failing that, the spot that touches least.
    if (!chosen) {
      let best = null
      for (const [i, [p, q]] of segments.entries()) {
        for (const box of besideSegment(p, q, w, h, i === 0 ? 10 : 4, { reach: 5, past: 3 * w })) {
          if (free(box)) { chosen = box; break }
          const cost = blocked.filter((b) => overlaps(box, b)).length * 2 + lines.filter(([a, c]) => touchesSegment(box, a, c)).length
          if (!best || cost < best.cost) best = { box, cost }
        }
        if (chosen) break
      }
      if (!chosen) {
        const [p] = segments[0]
        chosen = best ? best.box : { x: p.x + GAP, y: p.y - GAP - h, w, h }
      }
    }
    placed.set(String(edge.id), chosen)
    blocked.push(chosen)
  }
  return placed
}
