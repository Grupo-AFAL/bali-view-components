import { nodeFootprint, nodeBox, layoutLanes } from './geometry.js'

// What changed between two documents. An element is "changed" when what it
// says or where it belongs changed (name, type, description, lane, the event
// kind, the reference; for a connection its label and kind), not when it
// merely moved.
//
// How elements are paired (`compare_with: { match: }`):
//   'auto' — by id first, then what id left unpaired by name (the rules of
//            'name' below): versions whose ids an app recreated (a destructive
//            import) still pair, and two different processes pair by name.
//            The Component's default.
//   'id'   — by element id: two versions of ONE document, whose ids are
//            stable across saves (default). A renamed task is "changed".
//   'name' — by normalized name (case, accents and spacing ignored): two
//            different documents that share steps, whose ids mean nothing to
//            each other. A renamed task is "removed" plus "added" — nothing
//            else ties the two names together. A name repeated in a document
//            pairs first within the lane of the same name, then by position
//            along the flow. Unnamed elements (gateways, events) pair by
//            structure — the paired elements they come from and lead to —
//            and only without that evidence by type in order of appearance.
//            Lanes pair by name, connections by the pair of elements they join.
//
// A changed element carries its reasons (`reasons`): 'name', 'type',
// 'documentation', 'lane' (moved to another lane), 'event', 'reference' —
// for a connection 'label', 'ends', 'type'; for a lane 'name', 'kind'.
// Mirrors Bali::BpmnEditor::Component::COMPARE_MATCHES (contract_test.rb).
export const COMPARE_MATCHES = ['auto', 'id', 'name']

const same = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null)

export const normalizeName = (text) => String(text ?? '')
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/\s+/g, ' ').trim()

// Pairs `before` with `after` by `keyOf`; equal keys pair in order of
// appearance. → Map(after id → before element).
function pairBy (before, after, keyOf) {
  const queues = new Map()
  for (const element of before) {
    const key = keyOf(element)
    if (key == null) continue
    if (!queues.has(key)) queues.set(key, [])
    queues.get(key).push(element)
  }
  const pairs = new Map()
  for (const element of after) {
    const queue = queues.get(keyOf(element))
    if (queue && queue.length) pairs.set(String(element.id), queue.shift())
  }
  return pairs
}

// `changed (before, after)` → the reasons it changed, [] when it did not.
function classify (before, after, pairs, changed) {
  const current = {}
  const base = {}
  const reasons = { current: {}, base: {} }
  const matched = new Set()
  for (const element of after) {
    const id = String(element.id)
    const previous = pairs.get(id)
    if (!previous) { current[id] = 'added'; continue }
    matched.add(String(previous.id))
    const why = changed(previous, element)
    if (why.length) {
      current[id] = 'changed'
      base[String(previous.id)] = 'changed'
      reasons.current[id] = why
      reasons.base[String(previous.id)] = why
    }
  }
  for (const element of before) if (!matched.has(String(element.id))) base[String(element.id)] = 'removed'
  return { current, base, reasons }
}

const count = (side, state) => ['nodes', 'edges', 'lanes'].reduce((n, kind) => n + Object.values(side[kind]).filter((s) => s === state).length, 0)
const reasonsIf = (pairs) => pairs.filter(([, differs]) => differs).map(([reason]) => reason)

// Elements by name, for two different documents (see `match: 'name'` above).
// → Map(after id → before element).
function pairByName (before, after, { beforeLane, afterLane, beforeEdges, afterEdges, along }, known = new Map()) {
  const pairs = new Map()
  const taken = new Set()
  const take = (b, a) => { pairs.set(String(a.id), b); taken.add(String(b.id)) }
  const position = (n) => Number(n[along]) || 0
  const free = (list) => list.filter((n) => !taken.has(String(n.id)))

  // Named: within the same lane first, then along the flow.
  const named = (list) => {
    const groups = new Map()
    for (const n of [...list].sort((x, y) => position(x) - position(y))) {
      const key = normalizeName(n.name)
      if (!key) continue
      if (!groups.has(key)) groups.set(key, [])
      groups.get(key).push(n)
    }
    return groups
  }
  const beforeNamed = named(before)
  for (const [key, afters] of named(after)) {
    const befores = beforeNamed.get(key) || []
    for (const a of afters) {
      const b = free(befores).find((x) => beforeLane.get(String(x.lane_id)) === afterLane.get(String(a.lane_id)))
      if (b) take(b, a)
    }
    for (const a of afters) {
      if (pairs.has(String(a.id))) continue
      const b = free(befores)[0]
      if (b) take(b, a)
    }
  }

  // Unnamed: by the paired elements they come from and lead to, as long as
  // pairing one gives evidence for another.
  const unnamed = (list) => list.filter((n) => !normalizeName(n.name))
  const neighbours = (edges) => {
    const map = new Map()
    const add = (id, entry) => { if (!map.has(id)) map.set(id, new Set()); map.get(id).add(entry) }
    for (const e of edges) {
      add(String(e.target), `in:${e.source}`)
      add(String(e.source), `out:${e.target}`)
    }
    return map
  }
  const beforeAround = neighbours(beforeEdges)
  const afterAround = neighbours(afterEdges)
  const evidence = (b, a) => {
    const identity = new Map([...known, ...pairs].map(([afterId, element]) => [String(element.id), afterId]))
    let score = 0
    for (const entry of beforeAround.get(String(b.id)) || []) {
      const [side, id] = entry.split(/:(.*)/s)
      const mapped = identity.get(id)
      if (mapped && (afterAround.get(String(a.id)) || new Set()).has(`${side}:${mapped}`)) score++
    }
    return score
  }
  for (let found = true; found;) {
    found = false
    let best = null
    for (const a of unnamed(after)) {
      if (pairs.has(String(a.id))) continue
      for (const b of free(unnamed(before))) {
        if (b.type !== a.type) continue
        const score = evidence(b, a)
        if (score > 0 && (!best || score > best.score)) best = { a, b, score }
      }
    }
    if (best) { take(best.b, best.a); found = true }
  }
  // No structural evidence left: by type, in order of appearance.
  for (const a of unnamed(after)) {
    if (pairs.has(String(a.id))) continue
    const b = free(unnamed(before)).find((x) => x.type === a.type)
    if (b) take(b, a)
  }
  return pairs
}

export function diffDocuments (baseDoc, currentDoc, { match = 'id' } = {}) {
  const mode = COMPARE_MATCHES.includes(match) ? match : 'id'
  const before = { lanes: baseDoc.lanes || [], nodes: baseDoc.nodes || [], edges: baseDoc.edges || [] }
  const after = { lanes: currentDoc.lanes || [], nodes: currentDoc.nodes || [], edges: currentDoc.edges || [] }
  const byId = (list) => (element) => String(element.id)

  // Lanes: by id ('id'), by name ('name'), or by id and then by name ('auto').
  const laneByName = (lane) => `lane:${normalizeName(lane.name)}`
  const lanePairs = mode === 'name' ? pairBy(before.lanes, after.lanes, laneByName) : pairBy(before.lanes, after.lanes, byId())
  if (mode === 'auto') pairRest(lanePairs, before.lanes, after.lanes, (b, a) => pairBy(b, a, laneByName))
  const laneIdentity = new Map([...lanePairs].map(([currentId, previous]) => [String(previous.id), currentId]))

  // Where a node belongs, comparable across the two documents.
  const laneNames = (lanes) => new Map(lanes.map((l) => [String(l.id), normalizeName(l.name)]))
  const baseLaneName = laneNames(before.lanes)
  const currentLaneName = laneNames(after.lanes)
  const nameOptions = {
    beforeLane: baseLaneName,
    afterLane: currentLaneName,
    beforeEdges: before.edges,
    afterEdges: after.edges,
    along: currentDoc.orientation === 'vertical' ? 'y' : 'x'
  }
  const nodePairs = mode === 'name' ? pairByName(before.nodes, after.nodes, nameOptions) : pairBy(before.nodes, after.nodes, byId())
  const pairedById = mode === 'name' ? 0 : nodePairs.size
  if (mode === 'auto') pairRest(nodePairs, before.nodes, after.nodes, (b, a) => pairByName(b, a, nameOptions, nodePairs))
  const fromName = (b, a) => mode === 'name' || (mode === 'auto' && String(a.id) !== String(b.id))
  const nodeChanged = (a, b) => reasonsIf([
    ['name', fromName(a, b) ? normalizeName(a.name) !== normalizeName(b.name) : !same(a.name, b.name)],
    ['type', !same(a.type, b.type)],
    ['documentation', !same(a.documentation, b.documentation)],
    ['lane', mode === 'name'
      ? baseLaneName.get(String(a.lane_id)) !== currentLaneName.get(String(b.lane_id))
      : (laneIdentity.get(String(a.lane_id)) ?? `base:${a.lane_id}`) !== String(b.lane_id)],
    ['event', !same(a.event_definition && a.event_definition.kind, b.event_definition && b.event_definition.kind)],
    ['reference', !same(a.reference && a.reference.id, b.reference && b.reference.id)]
  ])
  const laneChanged = (a, b) => reasonsIf([['name', mode === 'name' || String(a.id) !== String(b.id) ? false : !same(a.name, b.name)], ['kind', !same(a.kind || 'internal', b.kind || 'internal')]])

  // A connection is the same one when it joins the same pair of elements.
  const identity = new Map() // base node id → current node id
  for (const [currentId, previous] of nodePairs) identity.set(String(previous.id), currentId)
  const ends = (side) => (edge) => {
    const end = (id) => (side === 'base' ? identity.get(String(id)) ?? `base:${id}` : String(id))
    return `${end(edge.source)}>${end(edge.target)}>${edge.type || 'sequence_flow'}`
  }
  const edgePairs = mode === 'name' ? pairEdges(before.edges, after.edges, ends('base'), ends('current')) : pairBy(before.edges, after.edges, byId())
  if (mode === 'auto') pairRest(edgePairs, before.edges, after.edges, (b, a) => pairEdges(b, a, ends('base'), ends('current')))
  const edgeChanged = (a, b) => (String(a.id) !== String(b.id) || mode === 'name'
    ? reasonsIf([['label', !same(a.label || '', b.label || '')]])
    : reasonsIf([['ends', ends('base')(a) !== ends('current')(b)], ['label', !same(a.label, b.label)], ['type', !same(a.type, b.type)]]))

  const lanes = classify(before.lanes, after.lanes, lanePairs, laneChanged)
  const nodes = classify(before.nodes, after.nodes, nodePairs, nodeChanged)
  const edges = classify(before.edges, after.edges, edgePairs, edgeChanged)
  const reasonsOf = (side) => ({ ...lanes.reasons[side], ...nodes.reasons[side], ...edges.reasons[side] })
  const current = { nodes: nodes.current, edges: edges.current, lanes: lanes.current, reasons: reasonsOf('current') }
  const base = { nodes: nodes.base, edges: edges.base, lanes: lanes.base, reasons: reasonsOf('base') }
  const merge = (kind) => ({ ...current[kind], ...Object.fromEntries(Object.entries(base[kind]).filter(([, s]) => s === 'removed')) })
  // Share of the paired elements that paired by id: most of them, and the two
  // documents are versions of one process (see sameProcess).
  const idShare = nodePairs.size ? pairedById / nodePairs.size : (mode === 'name' ? 0 : 1)
  return {
    match: mode,
    idShare,
    sameProcess: sameProcess(mode, idShare),
    // One map per kind, as before `match:`: current ids for added and changed,
    // base ids for removed. When elements pair by name an id may be in both
    // documents for different elements — read `current` and `base` instead.
    nodes: merge('nodes'),
    edges: merge('edges'),
    lanes: merge('lanes'),
    current,
    base,
    // base node id → current node id, for the elements that pair.
    identity,
    lanePairs: laneIdentity,
    summary: {
      added: count(current, 'added'),
      removed: count(base, 'removed'),
      changed: count(current, 'changed'),
      moved: Object.values(nodes.reasons.current).filter((why) => why.includes('lane')).length
    }
  }
}

// 'auto': what id left unpaired, paired by `pairer` (which returns the new
// pairs among the leftovers).
function pairRest (pairs, before, after, pairer) {
  const taken = new Set([...pairs.values()].map((e) => String(e.id)))
  const rest = pairer(before.filter((e) => !taken.has(String(e.id))), after.filter((e) => !pairs.has(String(e.id))))
  for (const [id, element] of rest) pairs.set(id, element)
}

// Two documents are versions of ONE process when they pair by id — `match:
// 'id'`, or 'auto' with more than half of the paired elements paired by id
// (SAME_PROCESS_SHARE). Only then is the overlay offered: two different
// processes drawn on one canvas would read as one.
export const SAME_PROCESS_SHARE = 0.5
export const sameProcess = (match, idShare) => match === 'id' || (match === 'auto' && idShare > SAME_PROCESS_SHARE)

function pairEdges (before, after, baseKey, currentKey) {
  return pairBy(before.map((e) => ({ ...e, __key: baseKey(e) })), after.map((e) => ({ ...e, __key: currentKey(e) })), (e) => e.__key)
}

const overlaps = (a, b, gap) => a.x < b.x + b.w + gap && b.x < a.x + a.w + gap && a.y < b.y + b.h + gap && b.y < a.y + a.h + gap
const GAP = 24
const TRIES = 40

// The current document plus, drawn where they used to be, the elements the
// base had and the current one dropped — the overlay view — with the state of
// every element keyed by its id in that drawing. A removed lane is added after
// the current ones, and a removed element goes to the band of its lane (the
// same lane, or the one it pairs with). One whose old place is taken (by an
// element of the current document, or by another removed one) moves along
// the flow until it is clear, so both read. A removed element whose id the
// current document reuses for something else gets a `removed:` id.
export function overlayView (baseDoc, currentDoc, diff = diffDocuments(baseDoc, currentDoc)) {
  const nodes = [...(currentDoc.nodes || [])]
  const taken = new Set([...nodes, ...(currentDoc.lanes || []), ...(currentDoc.edges || [])].map((e) => String(e.id)))
  const unique = (id) => (taken.has(String(id)) ? `removed:${id}` : String(id))

  const lanes = [...(currentDoc.lanes || [])]
  const laneState = { ...diff.current.lanes }
  const laneAs = new Map(diff.lanePairs) // base lane id → lane id in the overlay
  let order = Math.max(0, ...lanes.map((l) => Number(l.order) || 0))
  for (const lane of baseDoc.lanes || []) {
    if (diff.base.lanes[String(lane.id)] !== 'removed') continue
    const id = unique(lane.id)
    taken.add(id)
    lanes.push({ ...lane, id, order: ++order })
    laneAs.set(String(lane.id), id)
    laneState[id] = 'removed'
  }
  const from = layoutLanes(baseDoc)
  const to = layoutLanes({ ...currentDoc, lanes })
  const main = to.axis.main // the axis lanes stack on
  const along = currentDoc.orientation === 'vertical' ? 'y' : 'x'
  const boxes = nodes.filter((n) => n.type !== 'group').map(nodeFootprint)
  const drawnAs = new Map(diff.identity) // base node id → id in the overlay
  const nodeState = { ...diff.current.nodes }
  for (const node of baseDoc.nodes || []) {
    if (diff.base.nodes[String(node.id)] !== 'removed') continue
    const id = unique(node.id)
    const lane = laneAs.get(String(node.lane_id)) ?? node.lane_id
    let placed = { ...node, id, lane_id: lane }
    const was = from.byId.get(String(node.lane_id))
    const now = to.byId.get(String(lane))
    if (was && now) {
      const box = nodeBox(node)
      const size = main === 'y' ? box.h : box.w
      const within = Number(node[main]) - was.offset
      placed = { ...placed, [main]: now.offset + Math.max(0, Math.min(within, now.size - size)) }
    }
    for (let i = 0; i < TRIES && boxes.some((b) => overlaps(nodeFootprint(placed), b, GAP / 2)); i++) {
      const box = nodeFootprint(placed)
      placed = { ...placed, [along]: Number(placed[along]) + (along === 'x' ? box.w : box.h) + GAP }
    }
    boxes.push(nodeFootprint(placed))
    taken.add(id)
    drawnAs.set(String(node.id), id)
    nodeState[id] = 'removed'
    nodes.push(placed)
  }
  const edges = [...(currentDoc.edges || [])]
  const edgeState = { ...diff.current.edges }
  for (const edge of baseDoc.edges || []) {
    if (diff.base.edges[String(edge.id)] !== 'removed') continue
    const source = drawnAs.get(String(edge.source))
    const target = drawnAs.get(String(edge.target))
    if (!source || !target) continue
    const id = unique(edge.id)
    taken.add(id)
    // Its ends may have moved: the router draws it again.
    const { waypoints, ports, ...rest } = edge
    edges.push({ ...rest, id, source, target })
    edgeState[id] = 'removed'
  }
  return {
    doc: { ...currentDoc, lanes, nodes, edges },
    diff: { nodes: nodeState, edges: edgeState, lanes: laneState, reasons: diff.current.reasons },
    // base id → id in this drawing, for an element of the base document.
    drawnAs: { nodes: drawnAs, lanes: laneAs }
  }
}

export const overlayDocument = (baseDoc, currentDoc, diff) => overlayView(baseDoc, currentDoc, diff).doc

// "2 added · 1 removed · 3 changed (1 moved to another lane)", each count
// with its singular or plural (`t.count`, `compare_count_*_one/_other`).
export function summaryText (t, { added, removed, changed, moved = 0 }) {
  const counts = [t.count('compare_count_added', added), t.count('compare_count_removed', removed), t.count('compare_count_changed', changed)].join(' · ')
  return moved > 0 ? `${counts} ${t.count('compare_count_moved', moved)}` : counts
}
