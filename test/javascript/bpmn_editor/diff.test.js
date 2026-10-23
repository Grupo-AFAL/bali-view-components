import { test } from 'node:test'
import assert from 'node:assert/strict'
import { diffDocuments, overlayDocument, overlayView, summaryText, sameProcess, SAME_PROCESS_SHARE } from '../../../app/components/bali/bpmn_editor/model/diff.js'
import { nodeBox, layoutLanes } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, lanes, node, flow } from './helpers.js'

const base = () => doc({
  lanes: lanes('A', 'B'),
  nodes: [node('s', 'start_event', 'l1', 100, 90), node('t1', 'task', 'l1', 260, 90, { name: 'Validate' }), node('t2', 'task', 'l2', 460, 270, { name: 'Pay' })],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 't2')]
})

test('added, removed and changed by id; a move alone is not a change', () => {
  const current = base()
  current.nodes = current.nodes.filter((n) => n.id !== 't2')
  current.nodes.push(node('t3', 'task', 'l2', 600, 270, { name: 'Archive' }))
  current.nodes[1] = { ...current.nodes[1], name: 'Validate invoice' }
  current.nodes[0] = { ...current.nodes[0], x: current.nodes[0].x + 40 }
  current.edges = [flow('f1', 's', 't1', { label: 'go' })]
  const diff = diffDocuments(base(), current)
  assert.deepEqual(diff.nodes, { t1: 'changed', t3: 'added', t2: 'removed' })
  assert.deepEqual(diff.edges, { f1: 'changed', f2: 'removed' })
  assert.deepEqual(diff.summary, { added: 1, removed: 2, changed: 2, moved: 0 })
})

test('the overlay keeps what was removed so it can be drawn', () => {
  const current = base()
  current.nodes = current.nodes.filter((n) => n.id !== 't2')
  current.edges = current.edges.filter((e) => e.id !== 'f2')
  const overlay = overlayDocument(base(), current)
  assert.ok(overlay.nodes.some((n) => n.id === 't2'))
  assert.ok(overlay.edges.some((e) => e.id === 'f2'))
})

// Two different flows: nothing ties their ids together, only what the steps are called.
const supplier = () => doc({
  lanes: lanes('Requester', 'Purchasing'),
  nodes: [
    node('s', 'start_event', 'l1', 100, 90, { name: 'Request received' }),
    node('t1', 'task', 'l2', 260, 270, { name: 'Review documents' }),
    node('g', 'exclusive_gateway', 'l2', 420, 270, { name: '' }),
    node('t2', 'task', 'l2', 580, 270, { name: 'Register supplier' })
  ],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 'g'), flow('f3', 'g', 't2', { label: 'Yes' })]
})
const customer = () => doc({
  lanes: [{ id: 'x1', name: 'requester', kind: 'internal', order: 1, size: 180 }, { id: 'x2', name: 'Purchasing', kind: 'internal', order: 2, size: 180 }],
  nodes: [
    node('a', 'start_event', 'x1', 100, 90, { name: 'Request  received' }),
    node('b', 'task', 'x2', 260, 270, { name: 'REVIEW DOCUMENTS' }),
    node('c', 'exclusive_gateway', 'x2', 420, 270, { name: '' }),
    node('d', 'task', 'x2', 580, 270, { name: 'Register customer' })
  ],
  edges: [flow('e1', 'a', 'b'), flow('e2', 'b', 'c'), flow('e3', 'c', 'd', { label: 'Yes' })]
})

test('by name: different ids with the same normalized names are unchanged', () => {
  const diff = diffDocuments(supplier(), customer(), { match: 'name' })
  assert.equal(diff.match, 'name')
  assert.deepEqual(diff.current.nodes, { d: 'added' })
  assert.deepEqual(diff.base.nodes, { t2: 'removed' })
  assert.deepEqual(diff.current.lanes, {})
  // e1 and e2 join elements that pair; e3 now ends at a step the base never had.
  assert.deepEqual(diff.current.edges, { e3: 'added' })
  assert.deepEqual(diff.base.edges, { f3: 'removed' })
  assert.deepEqual(diff.summary, { added: 2, removed: 2, changed: 0, moved: 0 })
})

test('a renamed step: changed by id, removed plus added by name', () => {
  const renamed = supplier()
  renamed.nodes[1] = { ...renamed.nodes[1], name: 'Check documents' }
  assert.deepEqual(diffDocuments(supplier(), renamed).nodes, { t1: 'changed' })
  const byName = diffDocuments(supplier(), renamed, { match: 'name' })
  assert.deepEqual(byName.current.nodes, { t1: 'added' })
  assert.deepEqual(byName.base.nodes, { t1: 'removed' })
})

test('by name: same name in another lane, or another description, is changed', () => {
  const moved = customer()
  moved.nodes[1] = { ...moved.nodes[1], lane_id: 'x1', documentation: 'Twice' }
  const diff = diffDocuments(supplier(), moved, { match: 'name' })
  assert.equal(diff.current.nodes.b, 'changed')
  assert.equal(diff.base.nodes.t1, 'changed')
})

test('by name: a lane only one side has is added or removed', () => {
  const other = customer()
  other.lanes[1] = { ...other.lanes[1], name: 'Sales' }
  const diff = diffDocuments(supplier(), other, { match: 'name' })
  assert.deepEqual(diff.current.lanes, { x2: 'added' })
  assert.deepEqual(diff.base.lanes, { l2: 'removed' })
})

test('the overlay moves a removed element off one added in its place, so both read', () => {
  const current = base()
  current.nodes = current.nodes.filter((n) => n.id !== 't2')
  current.nodes.push(node('t3', 'task', 'l2', 470, 275, { name: 'Archive' }))
  const { doc: overlay, diff } = overlayView(base(), current)
  const removed = overlay.nodes.find((n) => n.id === 't2')
  const added = overlay.nodes.find((n) => n.id === 't3')
  const a = nodeBox(removed)
  const b = nodeBox(added)
  assert.ok(a.x >= b.x + b.w || b.x >= a.x + a.w || a.y >= b.y + b.h || b.y >= a.y + a.h, 'they do not overlap')
  assert.equal(removed.lane_id, 'l2', 'it stays in its lane')
  assert.equal(diff.nodes.t2, 'removed')
  assert.equal(diff.nodes.t3, 'added')
})

test('the overlay of two flows by name renames a removed element whose id the other reuses', () => {
  const other = customer()
  other.nodes.push(node('t2', 'task', 'x2', 900, 270, { name: 'Notify' }))
  const { doc: overlay, diff } = overlayView(supplier(), other, diffDocuments(supplier(), other, { match: 'name' }))
  const ids = overlay.nodes.map((n) => n.id)
  assert.equal(new Set(ids).size, ids.length, 'every id is drawn once')
  assert.ok(ids.includes('removed:t2'))
  assert.equal(diff.nodes['removed:t2'], 'removed')
  assert.equal(diff.nodes.t2, 'added')
  const removedEdge = overlay.edges.find((e) => diff.edges[e.id] === 'removed')
  assert.deepEqual([removedEdge.source, removedEdge.target], ['c', 'removed:t2'], 'its connection joins what the overlay draws')
  assert.equal(overlay.nodes.find((n) => n.id === 'removed:t2').lane_id, 'x2', 'into the lane of the same name')
})

test('the overlay draws a removed lane after the current ones, its elements in its band', () => {
  const other = customer() // no «Purchasing»: supplier's l2 is removed
  other.lanes = [other.lanes[0]]
  other.nodes = other.nodes.filter((n) => n.lane_id === 'x1')
  const { doc: overlay, diff } = overlayView(supplier(), other, diffDocuments(supplier(), other, { match: 'name' }))
  const removedLane = overlay.lanes.find((l) => diff.lanes[l.id] === 'removed')
  assert.ok(removedLane, 'the removed lane is drawn')
  assert.equal(removedLane.name, 'Purchasing')
  assert.ok(removedLane.order > other.lanes[0].order)
  const layout = layoutLanes(overlay)
  const band = layout.byId.get(String(removedLane.id))
  for (const n of overlay.nodes.filter((x) => x.lane_id === removedLane.id)) {
    const b = nodeBox(n)
    assert.ok(b.y >= band.offset && b.y + b.h <= band.offset + band.size, `${n.name} inside its lane`)
  }
})

// Two unnamed gateways in each flow, written in the opposite order: by
// order of appearance the split would pair with the merge.
const branching = (order) => {
  const nodes = [
    node('s', 'start_event', 'l1', 100, 90, { name: 'Start' }),
    node('a', 'task', 'l1', 260, 90, { name: 'Check' }),
    node('split', 'exclusive_gateway', 'l1', 400, 90, { name: '' }),
    node('b', 'task', 'l1', 540, 40, { name: 'Approve' }),
    node('c', 'task', 'l1', 540, 140, { name: 'Reject' }),
    node('merge', 'exclusive_gateway', 'l1', 680, 90, { name: '' }),
    node('e', 'end_event', 'l1', 820, 90, { name: 'Done' })
  ]
  const byId = Object.fromEntries(nodes.map((n) => [n.id, n]))
  return doc({
    lanes: lanes('A'),
    nodes: order.map((id) => byId[id]),
    edges: [flow('f1', 's', 'a'), flow('f2', 'a', 'split'), flow('f3', 'split', 'b'), flow('f4', 'split', 'c'),
      flow('f5', 'b', 'merge'), flow('f6', 'c', 'merge'), flow('f7', 'merge', 'e')]
  })
}

test('by name: unnamed gateways pair by the elements around them, not by order', () => {
  const before = branching(['s', 'a', 'split', 'b', 'c', 'merge', 'e'])
  const after = branching(['s', 'a', 'merge', 'b', 'c', 'split', 'e'])
  const diff = diffDocuments(before, after, { match: 'name' })
  assert.equal(diff.identity.get('split'), 'split')
  assert.equal(diff.identity.get('merge'), 'merge')
  assert.deepEqual(diff.summary, { added: 0, removed: 0, changed: 0, moved: 0 })
})

test('by name: without structural evidence, unnamed elements still pair by type and order', () => {
  const before = doc({ lanes: lanes('A'), nodes: [node('g1', 'parallel_gateway', 'l1', 100, 90, { name: '' })] })
  const after = doc({ lanes: lanes('A'), nodes: [node('x', 'parallel_gateway', 'l1', 400, 90, { name: '' })] })
  assert.equal(diffDocuments(before, after, { match: 'name' }).identity.get('g1'), 'x')
})

test('by name: a repeated name pairs within the lane of the same name first, then by position', () => {
  const before = doc({
    lanes: lanes('Sales', 'Finance'),
    nodes: [node('s1', 'task', 'l1', 100, 90, { name: 'Review' }), node('f1', 'task', 'l2', 300, 270, { name: 'Review' })]
  })
  // Same two steps, listed and placed the other way round.
  const after = doc({
    lanes: [{ id: 'y1', name: 'finance', order: 1, size: 180 }, { id: 'y2', name: 'SALES', order: 2, size: 180 }],
    nodes: [node('n1', 'task', 'y1', 100, 90, { name: 'Review' }), node('n2', 'task', 'y2', 300, 270, { name: 'review' })]
  })
  const diff = diffDocuments(before, after, { match: 'name' })
  assert.equal(diff.identity.get('f1'), 'n1')
  assert.equal(diff.identity.get('s1'), 'n2')
  assert.deepEqual(diff.summary, { added: 0, removed: 0, changed: 0, moved: 0 })
  // Two in the same lane: by position along the flow.
  const twice = doc({ lanes: lanes('Sales'), nodes: [node('p', 'task', 'l1', 100, 90, { name: 'Call' }), node('q', 'task', 'l1', 500, 90, { name: 'Call' })] })
  const swapped = doc({ lanes: lanes('Sales'), nodes: [node('late', 'task', 'l1', 600, 90, { name: 'Call' }), node('early', 'task', 'l1', 150, 90, { name: 'Call' })] })
  const byPosition = diffDocuments(twice, swapped, { match: 'name' })
  assert.equal(byPosition.identity.get('p'), 'early')
  assert.equal(byPosition.identity.get('q'), 'late')
})

test('a step moved to another lane is changed for the reason «lane», and counted as moved', () => {
  const moved = customer()
  moved.nodes = moved.nodes.map((n) => (n.id === 'b' ? { ...n, lane_id: 'x1' } : n))
  const diff = diffDocuments(supplier(), moved, { match: 'name' })
  assert.equal(diff.current.nodes.b, 'changed')
  assert.deepEqual(diff.current.reasons.b, ['lane'])
  assert.deepEqual(diff.base.reasons.t1, ['lane'])
  assert.equal(diff.summary.moved, 1)
  const byId = supplier()
  byId.nodes = byId.nodes.map((n) => (n.id === 't2' ? { ...n, lane_id: 'l1', name: 'Pay now' } : n))
  assert.deepEqual(diffDocuments(supplier(), byId).current.reasons.t2, ['name', 'lane'])
  const { diff: drawn } = overlayView(supplier(), moved, diff)
  assert.deepEqual(drawn.reasons.b, ['lane'], 'the overlay knows why too')
})

test('the summary says each count in its singular or plural', async () => {
  const { translator } = await import('../../../app/components/bali/bpmn_editor/i18n.js')
  const es = translator({
    compare_count_added_one: '%{count} agregado',
    compare_count_added_other: '%{count} agregados',
    compare_count_removed_one: '%{count} quitado',
    compare_count_removed_other: '%{count} quitados',
    compare_count_changed_one: '%{count} cambiado',
    compare_count_changed_other: '%{count} cambiados',
    compare_count_moved_one: '(%{count} movido de carril)',
    compare_count_moved_other: '(%{count} movidos de carril)'
  })
  assert.equal(summaryText(es, { added: 1, removed: 1, changed: 1, moved: 1 }), '1 agregado · 1 quitado · 1 cambiado (1 movido de carril)')
  assert.equal(summaryText(es, { added: 2, removed: 0, changed: 3, moved: 2 }), '2 agregados · 0 quitados · 3 cambiados (2 movidos de carril)')
  assert.equal(summaryText(es, { added: 1, removed: 2, changed: 0, moved: 0 }), '1 agregado · 2 quitados · 0 cambiados')
  const en = translator({})
  assert.equal(summaryText(en, { added: 1, removed: 2, changed: 1, moved: 1 }), '1 added · 2 removed · 1 changed (1 moved to another lane)')
})

// `match: 'auto'`: by id, then what is left by name.
const recreated = (d) => {
  const ids = new Map(d.nodes.map((n, i) => [n.id, `new${i}`]))
  const laneIds = new Map(d.lanes.map((l, i) => [l.id, `L${i}`]))
  return {
    ...d,
    lanes: d.lanes.map((l) => ({ ...l, id: laneIds.get(l.id) })),
    nodes: d.nodes.map((n) => ({ ...n, id: ids.get(n.id), lane_id: laneIds.get(n.lane_id) })),
    edges: d.edges.map((e, i) => ({ ...e, id: `x${i}`, source: ids.get(e.source), target: ids.get(e.target) }))
  }
}

test('auto: a version with stable ids pairs by id — a rename is a change, and it is the same process', () => {
  const next = supplier()
  next.nodes = next.nodes.map((n) => (n.id === 't2' ? { ...n, name: 'Ask for a fix' } : n))
  const diff = diffDocuments(supplier(), next, { match: 'auto' })
  assert.deepEqual(diff.current.nodes, { t2: 'changed' })
  assert.deepEqual(diff.current.reasons.t2, ['name'])
  assert.equal(diff.idShare, 1)
  assert.equal(diff.sameProcess, true)
})

test('auto: a version whose ids were recreated still pairs, by name — nothing reads as removed and added', () => {
  const diff = diffDocuments(supplier(), recreated(supplier()), { match: 'auto' })
  assert.deepEqual(diff.summary, { added: 0, removed: 0, changed: 0, moved: 0 })
  assert.equal(diffDocuments(supplier(), recreated(supplier()), { match: 'id' }).summary.removed > 0, true, 'by id alone everything would be removed')
  assert.equal(diff.idShare, 0)
  assert.equal(diff.sameProcess, false, 'no id in common: offered side by side only')
})

test('auto: ids first, then names for the rest', () => {
  const next = supplier()
  // One step recreated with a new id and the same name; another renamed in place.
  next.nodes = next.nodes.map((n) => (n.id === 't1' ? { ...n, id: 'n1' } : n.id === 't2' ? { ...n, name: 'Ask for a fix' } : n))
  next.edges = next.edges.map((e) => ({ ...e, source: e.source === 't1' ? 'n1' : e.source, target: e.target === 't1' ? 'n1' : e.target }))
  const diff = diffDocuments(supplier(), next, { match: 'auto' })
  assert.equal(diff.identity.get('t1'), 'n1', 'paired by name')
  assert.equal(diff.identity.get('t2'), 't2', 'paired by id, renamed')
  assert.deepEqual(diff.current.nodes, { t2: 'changed' })
  assert.equal(diff.sameProcess, true, 'most pair by id')
})

test('auto between two different processes pairs by name and is not the same process', () => {
  const diff = diffDocuments(supplier(), customer(), { match: 'auto' })
  const byName = diffDocuments(supplier(), customer(), { match: 'name' })
  assert.deepEqual(diff.summary, byName.summary)
  assert.equal(diff.sameProcess, false)
})

// Ids as the editor mints them (n_3…n_20, e_…, lane_…): two documents made
// in it share them without being related.
const editorMade = (names) => doc({
  lanes: [{ id: 'lane_1', name: 'Area', kind: 'internal', order: 1, size: 180 }, { id: 'lane_2', name: 'Office', kind: 'internal', order: 2, size: 180 }],
  nodes: names.map((name, i) => node(`n_${i + 3}`, 'task', i % 2 ? 'lane_2' : 'lane_1', 100 + i * 160, i % 2 ? 270 : 90, { name })),
  edges: names.slice(1).map((_, i) => flow(`e_${i + 21}`, `n_${i + 3}`, `n_${i + 4}`))
})
const STEPS = 18
const purchases = () => editorMade(Array.from({ length: STEPS }, (_, i) => `Purchase step ${i + 1}`))
const hiring = () => editorMade(Array.from({ length: STEPS }, (_, i) => (i === 4 ? 'Purchase step 5' : `Hiring step ${i + 1}`)))

test('auto: two unrelated documents whose ids the editor minted do not pair by those ids', () => {
  const diff = diffDocuments(purchases(), hiring(), { match: 'auto' })
  const byName = diffDocuments(purchases(), hiring(), { match: 'name' })
  assert.equal(diff.sameProcess, false, 'no overlay between different processes')
  assert.equal(diff.idShare, 0)
  assert.deepEqual(diff.summary, byName.summary)
  assert.equal(diff.summary.changed, 0, 'no step reads as renamed')
  assert.equal(diff.identity.get('n_7'), 'n_7', 'the one shared step pairs by its name')
})

test('auto: a version of an editor-made document with some steps renamed still pairs by id', () => {
  const next = purchases()
  next.nodes = next.nodes.map((n, i) => (i < STEPS / 2 ? { ...n, name: `${n.name} (revised)` } : n))
  const diff = diffDocuments(purchases(), next, { match: 'auto' })
  assert.equal(diff.sameProcess, true)
  assert.equal(diff.idShare, 1)
  assert.deepEqual(diff.summary, { added: 0, removed: 0, changed: STEPS / 2, moved: 0 })
})

test('the overlay is offered for versions of one process only', () => {
  assert.equal(sameProcess('id', 0), true)
  assert.equal(sameProcess('name', 1), false)
  assert.equal(sameProcess('auto', SAME_PROCESS_SHARE + 0.01), true)
  assert.equal(sameProcess('auto', SAME_PROCESS_SHARE), false)
})
