// The diagram's connections, routed together so that no two of them share a
// stretch of line, none crosses a node, a node's name or a pending badge, and
// each bends as little as it can.
//
// 1. Ports. Each connection gets a side of each node (BPMN reading
//    conventions: in horizontal lanes in by the left, out by the right; the
//    branches of a gateway out by the right, top and bottom, by where their
//    targets are; loops back under the flow; message flows vertically between
//    lanes), never the side a node's own name occupies. Endpoints sharing a
//    side are spread along it, ordered by where their other end lies, so they
//    do not start on the same point.
// 2. Paths. One at a time — the happy path first — each connection runs an A*
//    search over a sparse orthogonal grid: the borders of every obstacle plus
//    clearance, the stubs of its ports, channels 12 px off the lines already
//    drawn, and the midpoints in between. Stepping through an obstacle or along
//    a stretch another connection already uses is forbidden; length, bends and
//    crossings are costs. Parallel connections therefore end up in separate
//    channels ("nudging"), and a crossing is taken only when it is cheaper than
//    going around.
//
// Not elkjs: it lays out whole graphs, weighs ~1.4 MB and runs asynchronously;
// this routes into a layout the user owns. Measured on the 60-activity fixture:
// see routing.test.js.
import { categoryOf, CATEGORY, edgeType, isGateway } from './catalog.js'
import { layoutLanes, nodeBox } from './geometry.js'
import { nodeLabelBox, badgeBox, labelSide } from './labels.js'

export const STUB = 18
const CLEARANCE = 10
export const CHANNEL = 12
const BEND = 24
const CROSS = 40
const MARGIN = 140
const EPS = 0.5

const OPPOSITE = { left: 'right', right: 'left', top: 'bottom', bottom: 'top' }
const DIR = { left: { dx: -1, dy: 0 }, right: { dx: 1, dy: 0 }, top: { dx: 0, dy: -1 }, bottom: { dx: 0, dy: 1 } }

// ── ports ──────────────────────────────────────────────────────────────────

// A point on the node's outline on `side`, `offset` px from the side's middle
// (diamonds and circles have their outline inside the box).
export function portPoint (node, box, side, offset = 0) {
  const category = categoryOf(node)
  const horizontalSide = side === 'top' || side === 'bottom'
  const half = horizontalSide ? box.w / 2 : box.h / 2
  const o = Math.max(-half + 4, Math.min(half - 4, offset))
  let inset = 0
  if (category === CATEGORY.gateway) inset = Math.abs(o) * (horizontalSide ? box.h / box.w : box.w / box.h)
  else if (category === CATEGORY.event) {
    const r = Math.min(box.w, box.h) / 2
    inset = r - Math.sqrt(Math.max(0, r * r - o * o))
  }
  switch (side) {
    case 'top': return { x: box.cx + o, y: box.y + inset }
    case 'bottom': return { x: box.cx + o, y: box.y + box.h - inset }
    case 'left': return { x: box.x + inset, y: box.cy + o }
    default: return { x: box.x + box.w - inset, y: box.cy + o }
  }
}

// The port on `side` and the end of its stub: STUB px out from the node's
// box, on a whole pixel across the side so neighbouring lines stay parallel.
function endpoint (node, box, side, offset) {
  const point = portPoint(node, box, side, offset)
  const d = DIR[side]
  if (side === 'left' || side === 'right') {
    const y = Math.round(point.y)
    return { point: { x: point.x, y }, stub: { x: Math.round((side === 'left' ? box.x : box.x + box.w) + d.dx * STUB), y } }
  }
  const x = Math.round(point.x)
  return { point: { x, y: point.y }, stub: { x, y: Math.round((side === 'top' ? box.y : box.y + box.h) + d.dy * STUB) } }
}

function sidesFor (doc, edge, source, target, ctx) {
  const { forwardOut, forwardIn, mainKey, crossKey, orientation } = ctx
  const pinned = edge.ports || {}
  const a = ctx.boxes.get(String(source.id))
  const b = ctx.boxes.get(String(target.id))
  const along = (box) => box[crossKey === 'x' ? 'cx' : 'cy']
  const across = (box) => box[mainKey === 'y' ? 'cy' : 'cx']
  const span = (box) => (crossKey === 'x' ? box.w : box.h)
  const thick = (box) => (mainKey === 'y' ? box.h : box.w)
  const up = mainKey === 'y' ? 'top' : 'left'
  const down = mainKey === 'y' ? 'bottom' : 'right'
  const type = edgeType(edge)
  let out
  let into
  const ahead = along(b) - along(a)
  const offset = across(b) - across(a)
  if (type === 'association') {
    // Short and direct: the sides that face each other.
    if (Math.abs(ahead) > Math.abs(offset)) { out = ahead > 0 ? forwardOut : forwardIn; into = OPPOSITE[out] } else { out = offset > 0 ? down : up; into = OPPOSITE[out] }
  } else if (type === 'message_flow') {
    // Between participants, vertically across the lanes when it can.
    if (Math.abs(offset) > (thick(a) + thick(b)) / 2) { out = offset > 0 ? down : up; into = OPPOSITE[out] } else { out = ahead >= 0 ? forwardOut : forwardIn; into = OPPOSITE[out] }
  } else if (ahead < -(span(a) + span(b)) / 4) {
    // A loop back: under the flow, out and in by the bottom.
    out = down
    into = down
  } else {
    out = forwardOut
    into = forwardIn
    const branchy = isGateway(source) && ctx.outCount.get(String(source.id)) > 1
    const aligned = Math.abs(offset) <= Math.max(thick(a), thick(b)) / 2
    if (branchy && !aligned) out = offset > 0 ? down : up
    // Close behind, or straight above/below: in by the facing side.
    if (Math.abs(ahead) < (span(a) + span(b)) / 2 && !aligned) { out = offset > 0 ? down : up; into = OPPOSITE[out] }
    const merge = isGateway(target) && ctx.inCount.get(String(target.id)) > 1
    if (merge && !aligned && ahead > 0 && out !== forwardOut) into = forwardIn
  }
  if (['top', 'right', 'bottom', 'left'].includes(pinned.source)) out = pinned.source
  if (['top', 'right', 'bottom', 'left'].includes(pinned.target)) into = pinned.target
  // Never through a node's own name: a loop that would leave or enter by the
  // side the name is on goes over the flow instead; anything else takes the
  // reading-direction side.
  const loop = out === down && into === down
  if (labelSide(source, orientation) === out) out = loop ? up : (out === forwardOut ? up : forwardOut)
  if (labelSide(target, orientation) === into) into = loop ? up : (into === forwardIn ? up : forwardIn)
  return { out, into }
}

function assignPorts (doc, edges, ctx) {
  // node id → side → [{ edgeId, end, other }]
  const slots = new Map()
  const sides = new Map()
  for (const edge of edges) {
    const source = ctx.byId.get(String(edge.source))
    const target = ctx.byId.get(String(edge.target))
    sides.set(String(edge.id), sidesFor(doc, edge, source, target, ctx))
  }
  gatewayExits(edges, sides, ctx)
  for (const edge of edges) {
    const source = ctx.byId.get(String(edge.source))
    const target = ctx.byId.get(String(edge.target))
    const s = sides.get(String(edge.id))
    for (const [nodeId, side, end, otherId] of [[source.id, s.out, 'source', target.id], [target.id, s.into, 'target', source.id]]) {
      const key = `${nodeId}|${side}`
      if (!slots.has(key)) slots.set(key, [])
      slots.get(key).push({ edgeId: String(edge.id), end, other: ctx.boxes.get(String(otherId)) })
    }
  }
  const ports = new Map()
  for (const [key, list] of slots) {
    const [nodeId, side] = key.split('|')
    const node = ctx.byId.get(nodeId)
    const box = ctx.boxes.get(nodeId)
    const vertical = side === 'left' || side === 'right'
    list.sort((p, q) => (vertical ? p.other.cy - q.other.cy : p.other.cx - q.other.cx))
    const length = vertical ? box.h : box.w
    const step = list.length > 1 ? Math.min(CHANNEL, (length - 12) / (list.length - 1)) : 0
    // A gateway's name sits above it, left of the top port: endpoints on
    // its top side spread to the right only.
    const rightOnly = side === 'top' && isGateway(node)
    list.forEach((slot, i) => {
      const offset = rightOnly ? i * step : (i - (list.length - 1) / 2) * step
      if (!ports.has(slot.edgeId)) ports.set(slot.edgeId, {})
      ports.get(slot.edgeId)[slot.end] = { side, ...endpoint(node, box, side, offset) }
    })
  }
  for (const [edgeId, s] of sides) {
    const p = ports.get(edgeId)
    p.sourceSide = s.out
    p.targetSide = s.into
  }
  return ports
}

// The branches of a gateway with up to three ways out leave by distinct sides
// (Method and Style; Camunda's "model symmetrically"): the continuation in the
// gateway's own lane — or, with none, the branch most in line with it — goes
// straight out the reading-direction side, the others by the side towards
// their target (the farthest keeps it when two want the same one). A side the
// user pinned stays.
export const GATEWAY_DISTINCT_EXITS = 3

function gatewayExits (edges, sides, ctx) {
  const { forwardOut, mainKey, crossKey } = ctx
  const up = mainKey === 'y' ? 'top' : 'left'
  const down = mainKey === 'y' ? 'bottom' : 'right'
  const across = (box) => box[mainKey === 'y' ? 'cy' : 'cx']
  const along = (box) => box[crossKey === 'x' ? 'cx' : 'cy']
  const byGateway = new Map()
  for (const edge of edges) {
    if (edgeType(edge) !== 'sequence_flow') continue
    const source = ctx.byId.get(String(edge.source))
    if (!isGateway(source)) continue
    if (!byGateway.has(String(source.id))) byGateway.set(String(source.id), [])
    byGateway.get(String(source.id)).push(edge)
  }
  for (const [id, outs] of byGateway) {
    if (outs.length < 2 || outs.length > GATEWAY_DISTINCT_EXITS) continue
    const gateway = ctx.byId.get(id)
    const box = ctx.boxes.get(id)
    const pinned = (e) => ['top', 'right', 'bottom', 'left'].includes((e.ports || {}).source)
    const info = outs.map((edge) => {
      const target = ctx.byId.get(String(edge.target))
      const b = ctx.boxes.get(String(edge.target))
      return { edge, offset: across(b) - across(box), ahead: along(b) - along(box), sameLane: String(target.lane_id) === String(gateway.lane_id) }
    })
    const free = new Set([forwardOut, up, down])
    for (const i of info) if (pinned(i.edge)) free.delete(sides.get(String(i.edge.id)).out)
    const open = info.filter((i) => !pinned(i.edge))
    const candidates = open.filter((i) => i.ahead > 0)
    const main = [...candidates].sort((a, b) => (b.sameLane - a.sameLane) || (Math.abs(a.offset) - Math.abs(b.offset)) || (a.ahead - b.ahead))[0]
    const span = (b) => (crossKey === 'x' ? b.w : b.h)
    const set = (i, side) => {
      const s = sides.get(String(i.edge.id))
      const loop = s.out === s.into
      s.out = side
      if (loop || i.ahead <= 0) s.into = loop ? side : s.into
      else if (side === forwardOut) s.into = ctx.forwardIn
      else s.into = Math.abs(i.ahead) < (span(box) + span(ctx.boxes.get(String(i.edge.target)))) / 2 ? OPPOSITE[side] : ctx.forwardIn
      const target = ctx.byId.get(String(i.edge.target))
      if (labelSide(target, ctx.orientation) === s.into) s.into = ctx.forwardIn
      if (['top', 'right', 'bottom', 'left'].includes((i.edge.ports || {}).target)) s.into = i.edge.ports.target
      free.delete(side)
    }
    let straight = null
    if (main && free.has(forwardOut)) { set(main, forwardOut); straight = main }
    const rest = open.filter((i) => i !== straight).sort((a, b) => Math.abs(b.offset) - Math.abs(a.offset))
    for (const i of rest) {
      const wanted = i.offset < 0 ? up : down
      const side = [wanted, OPPOSITE[wanted], forwardOut].find((x) => free.has(x))
      if (side) set(i, side)
    }
  }
}

// ── occupancy ──────────────────────────────────────────────────────────────

function occupancy () {
  const h = new Map() // y → [[x1, x2]]
  const v = new Map() // x → [[y1, y2]]
  const key = (n) => Math.round(n * 2) / 2
  return {
    add (p, q) {
      if (Math.abs(p.y - q.y) < EPS) {
        const k = key(p.y)
        if (!h.has(k)) h.set(k, [])
        h.get(k).push([Math.min(p.x, q.x), Math.max(p.x, q.x)])
      } else {
        const k = key(p.x)
        if (!v.has(k)) v.set(k, [])
        v.get(k).push([Math.min(p.y, q.y), Math.max(p.y, q.y)])
      }
    },
    // Would p→q run along a stretch already drawn?
    overlaps (p, q) {
      const horizontal = Math.abs(p.y - q.y) < EPS
      const list = horizontal ? h.get(key(p.y)) : v.get(key(p.x))
      if (!list) return false
      const lo = horizontal ? Math.min(p.x, q.x) : Math.min(p.y, q.y)
      const hi = horizontal ? Math.max(p.x, q.x) : Math.max(p.y, q.y)
      return list.some(([a, b]) => Math.min(hi, b) - Math.max(lo, a) > EPS)
    },
    // Does p→q cross a drawn line at a right angle (inside both)?
    crossings (p, q) {
      const horizontal = Math.abs(p.y - q.y) < EPS
      const lo = horizontal ? Math.min(p.x, q.x) : Math.min(p.y, q.y)
      const hi = horizontal ? Math.max(p.x, q.x) : Math.max(p.y, q.y)
      const at = horizontal ? p.y : p.x
      let count = 0
      for (const [c, list] of horizontal ? v : h) {
        if (c <= lo + EPS || c >= hi - EPS) continue
        if (list.some(([a, b]) => at > a + EPS && at < b - EPS)) count++
      }
      return count
    },
    lines () { return { h, v } }
  }
}

// ── search ─────────────────────────────────────────────────────────────────

class Heap {
  constructor () { this.items = [] }
  push (item) {
    const a = this.items
    a.push(item)
    let i = a.length - 1
    while (i > 0) {
      const parent = (i - 1) >> 1
      if (a[parent][0] <= a[i][0]) break
      ;[a[parent], a[i]] = [a[i], a[parent]]
      i = parent
    }
  }

  pop () {
    const a = this.items
    const top = a[0]
    const last = a.pop()
    if (a.length) {
      a[0] = last
      let i = 0
      for (;;) {
        const l = 2 * i + 1
        const r = l + 1
        let m = i
        if (l < a.length && a[l][0] < a[m][0]) m = l
        if (r < a.length && a[r][0] < a[m][0]) m = r
        if (m === i) break
        ;[a[m], a[i]] = [a[i], a[m]]
        i = m
      }
    }
    return top
  }

  get size () { return this.items.length }
}

const uniqueSorted = (values) => [...new Set(values.map((v) => Math.round(v * 2) / 2))].sort((a, b) => a - b)

function withMidpoints (values) {
  const out = []
  for (let i = 0; i < values.length; i++) {
    out.push(values[i])
    if (i < values.length - 1 && values[i + 1] - values[i] > 24) out.push(Math.round((values[i] + values[i + 1]) / 2))
  }
  return out
}

function blockedSegment (p, q, obstacles) {
  for (const r of obstacles) {
    if (Math.abs(p.x - q.x) < EPS) {
      if (p.x > r.x + EPS && p.x < r.x + r.w - EPS && Math.max(p.y, q.y) > r.y + EPS && Math.min(p.y, q.y) < r.y + r.h - EPS) return true
    } else if (p.y > r.y + EPS && p.y < r.y + r.h - EPS && Math.max(p.x, q.x) > r.x + EPS && Math.min(p.x, q.x) < r.x + r.w - EPS) return true
  }
  return false
}

// A* from `start` (leaving in direction `startDir`) to `goal` (arriving in
// direction `goalDir`) over the grid built from the region's coordinates.
function search (start, startDir, goal, goalDir, obstacles, occupied, region) {
  const inRegion = (r) => r.x < region.x2 && r.x + r.w > region.x1 && r.y < region.y2 && r.y + r.h > region.y1
  const local = obstacles.filter(inRegion)
  const xs = [start.x, goal.x, region.x1, region.x2]
  const ys = [start.y, goal.y, region.y1, region.y2]
  for (const r of local) { xs.push(r.x, r.x + r.w); ys.push(r.y, r.y + r.h) }
  const { h, v } = occupied.lines()
  for (const [y] of h) if (y > region.y1 && y < region.y2) ys.push(y - CHANNEL, y + CHANNEL)
  for (const [x] of v) if (x > region.x1 && x < region.x2) xs.push(x - CHANNEL, x + CHANNEL)
  const X = withMidpoints(uniqueSorted(xs.filter((x) => x >= region.x1 && x <= region.x2)))
  const Y = withMidpoints(uniqueSorted(ys.filter((y) => y >= region.y1 && y <= region.y2)))
  const xi = new Map(X.map((x, i) => [x, i]))
  const yi = new Map(Y.map((y, i) => [y, i]))
  const sx = xi.get(Math.round(start.x * 2) / 2)
  const sy = yi.get(Math.round(start.y * 2) / 2)
  const gx = xi.get(Math.round(goal.x * 2) / 2)
  const gy = yi.get(Math.round(goal.y * 2) / 2)
  if (sx == null || sy == null || gx == null || gy == null) return null
  const DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]]
  const dirIndex = (d) => DIRS.findIndex(([a, b]) => a === d.dx && b === d.dy)
  const W = X.length
  const id = (x, y, d) => ((y * W + x) << 2) | d
  const best = new Map()
  const from = new Map()
  const heap = new Heap()
  const sd = dirIndex(startDir)
  const gd = dirIndex(goalDir)
  const heuristic = (x, y) => Math.abs(X[x] - X[gx]) + Math.abs(Y[y] - Y[gy])
  best.set(id(sx, sy, sd), 0)
  heap.push([heuristic(sx, sy), 0, sx, sy, sd])
  let found = null
  let expanded = 0
  while (heap.size) {
    const [, cost, x, y, d] = heap.pop()
    const key = id(x, y, d)
    if (cost > (best.get(key) ?? Infinity)) continue
    if (x === gx && y === gy && d === gd) { found = key; break }
    if (++expanded > 60000) break
    for (let nd = 0; nd < 4; nd++) {
      if (nd === (d ^ 1)) continue // no U-turn on the spot
      const nx = x + DIRS[nd][0]
      const ny = y + DIRS[nd][1]
      if (nx < 0 || ny < 0 || nx >= W || ny >= Y.length) continue
      const p = { x: X[x], y: Y[y] }
      const q = { x: X[nx], y: Y[ny] }
      if (blockedSegment(p, q, local) || occupied.overlaps(p, q)) continue
      const step = Math.abs(q.x - p.x) + Math.abs(q.y - p.y) + (nd !== d ? BEND : 0) + occupied.crossings(p, q) * CROSS
      const next = cost + step
      const nkey = id(nx, ny, nd)
      if (next < (best.get(nkey) ?? Infinity)) {
        best.set(nkey, next)
        from.set(nkey, key)
        heap.push([next + heuristic(nx, ny), next, nx, ny, nd])
      }
    }
  }
  if (found == null) return null
  const path = []
  for (let k = found; k != null; k = from.get(k)) {
    const cell = k >> 2
    path.push({ x: X[cell % W], y: Y[Math.floor(cell / W)] })
  }
  return path.reverse()
}

function simplify (points) {
  const out = []
  for (const p of points) {
    const k = out.length
    if (k && Math.abs(out[k - 1].x - p.x) < EPS && Math.abs(out[k - 1].y - p.y) < EPS) continue
    if (k >= 2) {
      const a = out[k - 2]
      const b = out[k - 1]
      if ((Math.abs(a.x - b.x) < EPS && Math.abs(b.x - p.x) < EPS) || (Math.abs(a.y - b.y) < EPS && Math.abs(b.y - p.y) < EPS)) { out[k - 1] = { x: p.x, y: p.y }; continue }
    }
    out.push({ x: p.x, y: p.y })
  }
  return out
}

// ── the diagram ────────────────────────────────────────────────────────────

const ORDER = { sequence_flow: 0, message_flow: 1, association: 2 }

export function routeDiagram (doc, { order = null } = {}) {
  const layout = layoutLanes(doc)
  const orientation = layout.orientation
  const horizontal = orientation === 'horizontal'
  const nodes = doc.nodes || []
  const byId = new Map(nodes.map((n) => [String(n.id), n]))
  const boxes = new Map(nodes.map((n) => [String(n.id), nodeBox(n)]))
  const outCount = new Map()
  const inCount = new Map()
  for (const e of doc.edges || []) {
    if (edgeType(e) !== 'sequence_flow') continue
    outCount.set(String(e.source), (outCount.get(String(e.source)) || 0) + 1)
    inCount.set(String(e.target), (inCount.get(String(e.target)) || 0) + 1)
  }
  const ctx = {
    byId,
    boxes,
    outCount,
    inCount,
    orientation,
    forwardOut: horizontal ? 'right' : 'bottom',
    forwardIn: horizontal ? 'left' : 'top',
    mainKey: layout.axis.main,
    crossKey: layout.axis.cross
  }
  const edges = (doc.edges || []).filter((e) => byId.has(String(e.source)) && byId.has(String(e.target)) && String(e.source) !== String(e.target))
  const rank = new Map((order || []).map((id, i) => [String(id), i]))
  const along = (e) => { const b = boxes.get(String(e.source)); return horizontal ? b.cx : b.cy }
  edges.sort((a, b) => (ORDER[edgeType(a)] - ORDER[edgeType(b)]) ||
    ((rank.get(String(a.source)) ?? 1e9) - (rank.get(String(b.source)) ?? 1e9)) || (along(a) - along(b)))
  const ports = assignPorts(doc, edges, ctx)

  // What no line may cross: nodes (plus clearance), names, badges, headers.
  const obstacles = []
  for (const n of nodes) {
    if (n.type === 'group') continue
    const b = boxes.get(String(n.id))
    obstacles.push({ x: b.x - CLEARANCE, y: b.y - CLEARANCE, w: b.w + CLEARANCE * 2, h: b.h + CLEARANCE * 2 })
    const label = nodeLabelBox(n, orientation)
    if (label) obstacles.push({ x: label.x - 3, y: label.y - 3, w: label.w + 6, h: label.h + 6 })
    if (categoryOf(n) !== CATEGORY.artifact && categoryOf(n) !== CATEGORY.data) {
      const badge = badgeBox(n)
      obstacles.push({ x: badge.x - 2, y: badge.y - 2, w: badge.w + 4, h: badge.h + 4 })
    }
  }
  if (layout.entries.length) {
    obstacles.push(horizontal
      ? { x: -100000, y: 0, w: 100000 + layout.header, h: layout.thickness }
      : { x: 0, y: -100000, w: layout.thickness, h: 100000 + layout.header })
  }
  const all = [...boxes.values()]
  const bounds = {
    x1: Math.min(0, ...all.map((b) => b.x)) - MARGIN,
    y1: Math.min(0, ...all.map((b) => b.y)) - MARGIN,
    x2: Math.max(horizontal ? layout.length : layout.thickness, ...all.map((b) => b.x + b.w)) + MARGIN,
    y2: Math.max(horizontal ? layout.thickness : layout.length, ...all.map((b) => b.y + b.h)) + MARGIN
  }

  // Every port's stub is reserved before any search, so no line takes the
  // stretch another connection needs to reach its own port.
  const occupied = occupancy()
  for (const port of ports.values()) {
    occupied.add(port.source.point, port.source.stub)
    occupied.add(port.target.point, port.target.stub)
  }
  const routes = new Map()
  for (const edge of edges) {
    const id = String(edge.id)
    const port = ports.get(id)
    const s = port.source
    const t = port.target
    let points = null
    let failed = false
    if (Array.isArray(edge.waypoints) && edge.waypoints.length >= 2) {
      points = edge.waypoints.map((p) => ({ x: Number(p.x), y: Number(p.y) }))
    } else {
      const own = [String(edge.source), String(edge.target)]
      // The stubs leave through the clearance of their own nodes.
      const stubFree = obstacles.filter((r) => !own.some((nid) => {
        const b = boxes.get(nid)
        return r.x === b.x - CLEARANCE && r.y === b.y - CLEARANCE && r.w === b.w + CLEARANCE * 2
      }))
      const ownBlocks = own.map((nid) => { const b = boxes.get(nid); return { x: b.x + 1, y: b.y + 1, w: b.w - 2, h: b.h - 2 } })
      const blockers = [...stubFree, ...ownBlocks]
      const startDir = DIR[s.side]
      const goalDir = { dx: -DIR[t.side].dx, dy: -DIR[t.side].dy }
      const regionOf = (margin) => ({
        x1: Math.max(bounds.x1, Math.min(s.stub.x, t.stub.x) - margin),
        x2: Math.min(bounds.x2, Math.max(s.stub.x, t.stub.x) + margin),
        y1: Math.max(bounds.y1, Math.min(s.stub.y, t.stub.y) - margin),
        y2: Math.min(bounds.y2, Math.max(s.stub.y, t.stub.y) + margin)
      })
      let path = search(s.stub, startDir, t.stub, goalDir, blockers, occupied, regionOf(MARGIN))
      if (!path) path = search(s.stub, startDir, t.stub, goalDir, blockers, occupied, bounds)
      if (!path) {
        // The preferred sides are walled in (a node right above the target,
        // say): try the other sides, nearest pair first.
        const alternative = otherSides(edge, ctx, blockers, occupied, bounds, siblingExits(edge, edges, ports, ctx))
        if (alternative) {
          ({ path } = alternative)
          s.side = alternative.s.side; s.point = alternative.s.point; s.stub = alternative.s.stub
          t.side = alternative.t.side; t.point = alternative.t.point; t.stub = alternative.t.stub
          port.sourceSide = s.side
          port.targetSide = t.side
          occupied.add(s.point, s.stub)
          occupied.add(t.point, t.stub)
        }
      }
      if (!path) {
        // No clean way exists: still connect, as straight as possible, and
        // say so — auto-arrange makes room and routes again.
        path = [s.stub, { x: t.stub.x, y: s.stub.y }, t.stub]
        failed = true
      }
      points = simplify([s.point, ...path, t.point])
    }
    for (let i = 0; i < points.length - 1; i++) occupied.add(points[i], points[i + 1])
    routes.set(id, { points, sourceSide: port.sourceSide, targetSide: port.targetSide, label: labelAnchor(points), failed })
  }
  // A connection from a node to itself loops around its top-right corner.
  for (const edge of doc.edges || []) {
    if (String(edge.source) !== String(edge.target) || !boxes.has(String(edge.source))) continue
    const b = boxes.get(String(edge.source))
    const points = [{ x: b.x + b.w, y: b.cy }, { x: b.x + b.w + 24, y: b.cy }, { x: b.x + b.w + 24, y: b.y - 24 }, { x: b.cx, y: b.y - 24 }, { x: b.cx, y: b.y }]
    routes.set(String(edge.id), { points, sourceSide: 'right', targetSide: 'top', label: labelAnchor(points) })
  }
  return routes
}

// The sides a gateway's other branches leave by, which a retry must not take.
function siblingExits (edge, edges, ports, ctx) {
  const source = ctx.byId.get(String(edge.source))
  if (edgeType(edge) !== 'sequence_flow' || !isGateway(source) || ctx.outCount.get(String(source.id)) > GATEWAY_DISTINCT_EXITS) return new Set()
  return new Set(edges
    .filter((e) => e !== edge && String(e.source) === String(edge.source) && edgeType(e) === 'sequence_flow')
    .map((e) => ports.get(String(e.id)).sourceSide))
}

function otherSides (edge, ctx, blockers, occupied, bounds, taken = new Set()) {
  const source = ctx.byId.get(String(edge.source))
  const target = ctx.byId.get(String(edge.target))
  const a = ctx.boxes.get(String(edge.source))
  const b = ctx.boxes.get(String(edge.target))
  const inside = (p) => blockers.some((r) => p.x > r.x && p.x < r.x + r.w && p.y > r.y && p.y < r.y + r.h)
  const endFor = (node, box, side) => {
    if (labelSide(node, ctx.orientation) === side) return null
    for (const offset of [0, CHANNEL, -CHANNEL, 2 * CHANNEL, -2 * CHANNEL]) {
      if (side === 'top' && isGateway(node) && offset < 0) continue
      const { point, stub } = endpoint(node, box, side, offset)
      if (!occupied.overlaps(point, stub) && !inside(stub)) return { side, point, stub }
    }
    return null
  }
  const pairs = []
  for (const out of ['right', 'bottom', 'top', 'left'].filter((side) => !taken.has(side))) {
    for (const into of ['left', 'top', 'bottom', 'right']) {
      const s = endFor(source, a, out)
      const t = endFor(target, b, into)
      if (s && t) pairs.push({ s, t, d: Math.abs(s.stub.x - t.stub.x) + Math.abs(s.stub.y - t.stub.y) })
    }
  }
  pairs.sort((p, q) => p.d - q.d)
  for (const pair of pairs) {
    const goalDir = { dx: -DIR[pair.t.side].dx, dy: -DIR[pair.t.side].dy }
    const path = search(pair.s.stub, DIR[pair.s.side], pair.t.stub, goalDir, blockers, occupied, bounds)
    if (path) return { ...pair, path }
  }
  return null
}

// Midpoint of the longest segment (kept for callers that want one anchor).
export function labelAnchor (points) {
  let index = 0
  let longest = -1
  for (let i = 0; i < points.length - 1; i++) {
    const length = Math.abs(points[i].x - points[i + 1].x) + Math.abs(points[i].y - points[i + 1].y)
    if (length > longest) { longest = length; index = i }
  }
  const a = points[index]
  const b = points[index + 1] || a
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2, vertical: Math.abs(a.x - b.x) < EPS }
}
