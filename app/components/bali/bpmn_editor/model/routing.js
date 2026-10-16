// Orthogonal connector routing that goes around other elements.
//
// Not elkjs: elkjs is ~1.4 MB, asynchronous, and lays out whole graphs. Here
// one connection is routed between boxes that are already placed, on every
// frame of a drag. The router tries a small set of orthogonal candidates — one
// or two bends through the midpoints and through the gutters around every
// obstacle — rejects any whose segments cross another element, and keeps the
// shortest, with each bend costing BEND_COST of length. Sixty connections
// route in ~8 ms (routing.test.js), so it runs on every frame of a drag.
import { nodeBox } from './geometry.js'
import { routeDiagram } from './router.js'

export const SIDES = ['top', 'right', 'bottom', 'left']
const STUB = 18
const CLEARANCE = 8
const BEND_COST = 30

export function port (box, side) {
  switch (side) {
    case 'top': return { x: box.cx, y: box.y, dx: 0, dy: -1 }
    case 'bottom': return { x: box.cx, y: box.y + box.h, dx: 0, dy: 1 }
    case 'left': return { x: box.x, y: box.cy, dx: -1, dy: 0 }
    default: return { x: box.x + box.w, y: box.cy, dx: 1, dy: 0 }
  }
}

// The side each end leaves from when the edge says `auto`: straight ahead
// when the target is clearly further along, back along the bottom when it is
// behind on the same row, otherwise vertically.
export function autoSides (a, b) {
  const dx = b.cx - a.cx
  const dy = b.cy - a.cy
  const apart = (a.w + b.w) / 2 + 10
  if (dx > apart) return ['right', 'left']
  if (dx < -apart && Math.abs(dy) < 20) return ['bottom', 'bottom']
  if (dy > (a.h + b.h) / 2) return ['bottom', 'top']
  if (dy < -(a.h + b.h) / 2) return ['top', 'bottom']
  if (dx < -apart) return ['left', 'right']
  return dy >= 0 ? ['bottom', 'top'] : ['top', 'bottom']
}

function segmentHits (p, q, r) {
  if (p.x === q.x) {
    const y1 = Math.min(p.y, q.y)
    const y2 = Math.max(p.y, q.y)
    return p.x > r.x && p.x < r.x + r.w && y2 > r.y && y1 < r.y + r.h
  }
  const x1 = Math.min(p.x, q.x)
  const x2 = Math.max(p.x, q.x)
  return p.y > r.y && p.y < r.y + r.h && x2 > r.x && x1 < r.x + r.w
}

export function simplify (points) {
  const out = []
  for (const p of points) {
    const k = out.length
    if (k && out[k - 1].x === p.x && out[k - 1].y === p.y) continue
    if (k >= 2) {
      const a = out[k - 2]
      const b = out[k - 1]
      if ((a.x === b.x && b.x === p.x) || (a.y === b.y && b.y === p.y)) {
        out[k - 1] = { x: p.x, y: p.y }
        continue
      }
    }
    out.push({ x: p.x, y: p.y })
  }
  return out
}

// Midpoint of the longest segment: the label rides with the line it names.
export function labelPoint (points) {
  let index = 0
  let longest = -1
  for (let i = 0; i < points.length - 1; i++) {
    const length = Math.abs(points[i].x - points[i + 1].x) + Math.abs(points[i].y - points[i + 1].y)
    if (length > longest) { longest = length; index = i }
  }
  const a = points[index]
  const b = points[index + 1] || a
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2, vertical: a.x === b.x }
}

function selfLoop (box) {
  const p1 = port(box, 'right')
  const p2 = port(box, 'top')
  return [p1, { x: p1.x + 24, y: p1.y }, { x: p1.x + 24, y: box.y - 24 }, { x: p2.x, y: box.y - 24 }, p2]
}

// `obstacles` are the boxes of every other node (pool-relative); `edge.ports`
// may pin either end to a side. Returns { points, label, sourceSide, targetSide }.
export function routeEdge (edge, sourceBox, targetBox, obstacles = []) {
  if (!sourceBox || !targetBox) return null
  if (Array.isArray(edge.waypoints) && edge.waypoints.length >= 2) {
    const points = edge.waypoints.map((p) => ({ x: Number(p.x), y: Number(p.y) }))
    return { points, label: labelPoint(points), sourceSide: 'auto', targetSide: 'auto', manual: true }
  }
  if (edge.source === edge.target) {
    const points = selfLoop(sourceBox)
    return { points, label: labelPoint(points), sourceSide: 'right', targetSide: 'top' }
  }
  const ports = edge.ports || {}
  const [autoSource, autoTarget] = autoSides(sourceBox, targetBox)
  const sourceSide = SIDES.includes(ports.source) ? ports.source : autoSource
  const targetSide = SIDES.includes(ports.target) ? ports.target : autoTarget
  const p1 = port(sourceBox, sourceSide)
  const p2 = port(targetBox, targetSide)
  const s1 = { x: p1.x + p1.dx * STUB, y: p1.y + p1.dy * STUB }
  const s2 = { x: p2.x + p2.dx * STUB, y: p2.y + p2.dy * STUB }

  const blocks = obstacles.map((r) => ({ x: r.x - CLEARANCE, y: r.y - CLEARANCE, w: r.w + CLEARANCE * 2, h: r.h + CLEARANCE * 2 }))
  const ends = [sourceBox, targetBox].map((r) => ({ x: r.x + 1, y: r.y + 1, w: r.w - 2, h: r.h - 2 }))

  const xs = new Set([Math.round((s1.x + s2.x) / 2), s1.x, s2.x])
  const ys = new Set([Math.round((s1.y + s2.y) / 2), s1.y, s2.y])
  for (const r of blocks) {
    xs.add(r.x - CLEARANCE); xs.add(r.x + r.w + CLEARANCE)
    ys.add(r.y - CLEARANCE); ys.add(r.y + r.h + CLEARANCE)
  }
  for (const r of [sourceBox, targetBox]) {
    xs.add(r.x - 26); xs.add(r.x + r.w + 26)
    ys.add(r.y - 26); ys.add(r.y + r.h + 26)
  }
  const candidates = [[{ x: s2.x, y: s1.y }], [{ x: s1.x, y: s2.y }]]
  for (const mx of xs) candidates.push([{ x: mx, y: s1.y }, { x: mx, y: s2.y }])
  for (const my of ys) candidates.push([{ x: s1.x, y: my }, { x: s2.x, y: my }])

  let best = null
  let bestScore = Infinity
  for (const middle of candidates) {
    const points = simplify([p1, s1, ...middle, s2, p2])
    let ok = true
    let length = 0
    for (let i = 0; i < points.length - 1 && ok; i++) {
      const p = points[i]
      const q = points[i + 1]
      if (p.x !== q.x && p.y !== q.y) { ok = false; break }
      length += Math.abs(p.x - q.x) + Math.abs(p.y - q.y)
      if (blocks.some((r) => segmentHits(p, q, r))) ok = false
      else if (i > 0 && i < points.length - 2 && ends.some((r) => segmentHits(p, q, r))) ok = false
    }
    if (!ok) continue
    const score = length + (points.length - 2) * BEND_COST
    if (score < bestScore) { bestScore = score; best = points }
  }
  if (!best) {
    const mx = (s1.x + s2.x) / 2
    best = simplify([p1, s1, { x: mx, y: s1.y }, { x: mx, y: s2.y }, s2, p2])
  }
  return { points: best, label: labelPoint(best), sourceSide, targetSide }
}

// A group is a frame drawn around other elements, so lines may cross it.
export function boxesById (doc) {
  return new Map((doc.nodes || []).map((n) => [String(n.id), { ...nodeBox(n), passThrough: n.type === 'group' }]))
}

// The routes of the document's connections. The full router (router.js)
// keeps lines apart and around everything; while a node is being dragged the
// quick one below re-routes only the connections that touch it, every frame.
export function routeAll (doc, options = {}) {
  if (options.onlyIds) return quickRouteAll(doc, options)
  return routeDiagram(doc, options)
}

export function quickRouteAll (doc, { previous = null, onlyIds = null, boxes = null } = {}) {
  const byId = boxes || boxesById(doc)
  const routes = new Map()
  for (const edge of doc.edges || []) {
    const id = String(edge.id)
    if (onlyIds && !onlyIds.has(id) && previous && previous.has(id)) {
      routes.set(id, previous.get(id))
      continue
    }
    const source = byId.get(String(edge.source))
    const target = byId.get(String(edge.target))
    if (!source || !target) continue
    const obstacles = []
    for (const [nodeId, box] of byId) {
      if (nodeId !== String(edge.source) && nodeId !== String(edge.target) && !box.passThrough) obstacles.push(box)
    }
    routes.set(id, routeEdge(edge, source, target, obstacles))
  }
  return routes
}

export const pathFor = (points) => points.map((p, i) => `${i ? 'L' : 'M'}${p.x},${p.y}`).join(' ')

export function distanceToSegment (p, a, b) {
  const dx = b.x - a.x
  const dy = b.y - a.y
  const l = dx * dx + dy * dy || 1
  const t = Math.max(0, Math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / l))
  return Math.hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
}

export function distanceToRoute (point, route) {
  let best = Infinity
  for (let i = 0; i < route.points.length - 1; i++) {
    best = Math.min(best, distanceToSegment(point, route.points[i], route.points[i + 1]))
  }
  return best
}

// Line jumps: where a horizontal stretch crosses a vertical stretch of a
// connection drawn before it, the later one hops over (a small arc), so a
// crossing never reads as a junction. id → [{ segment, x }].
export function findJumps (routes) {
  const drawn = []
  const jumps = new Map()
  for (const [id, route] of routes) {
    const found = []
    const points = route.points
    for (let i = 0; i < points.length - 1; i++) {
      const p = points[i]
      const q = points[i + 1]
      if (Math.abs(p.y - q.y) > 0.5) continue
      const lo = Math.min(p.x, q.x) + 6
      const hi = Math.max(p.x, q.x) - 6
      for (const [a, b] of drawn) {
        if (a.x < lo || a.x > hi) continue
        if (p.y > Math.min(a.y, b.y) + 0.5 && p.y < Math.max(a.y, b.y) - 0.5) found.push({ segment: i, x: a.x })
      }
    }
    if (found.length) jumps.set(id, found)
    for (let i = 0; i < points.length - 1; i++) {
      if (Math.abs(points[i].x - points[i + 1].x) < 0.5 && Math.abs(points[i].y - points[i + 1].y) > 0.5) drawn.push([points[i], points[i + 1]])
    }
  }
  return jumps
}

const JUMP = 5

export function pathWithJumps (points, jumps = [], dx = 0, dy = 0) {
  let d = `M${points[0].x + dx},${points[0].y + dy}`
  for (let i = 1; i < points.length; i++) {
    const p = points[i - 1]
    const q = points[i]
    const here = jumps.filter((j) => j.segment === i - 1)
    if (here.length) {
      const sign = Math.sign(q.x - p.x)
      for (const { x } of here.sort((a, b) => sign * (a.x - b.x))) {
        d += ` L${x - sign * JUMP + dx},${p.y + dy} A${JUMP},${JUMP} 0 0 ${sign > 0 ? 1 : 0} ${x + sign * JUMP + dx},${p.y + dy}`
      }
    }
    d += ` L${q.x + dx},${q.y + dy}`
  }
  return d
}
