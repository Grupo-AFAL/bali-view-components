import { test } from 'node:test'
import assert from 'node:assert/strict'
import * as ops from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { nodeSize, MIN_NODE_SIZE, MAX_NODE_SIZE, isResizable } from '../../../app/components/bali/bpmn_editor/model/catalog.js'
import { layoutLanes, insideLane, nodeBox, boxesOverlap } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { insideLabelBox, badgeTabBox, markerZone } from '../../../app/components/bali/bpmn_editor/model/labels.js'
import { routeAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { autoLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { forSave, normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { toBpmnXml } from '../../../app/components/bali/bpmn_editor/model/bpmnXml.js'
import { arrange } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { measure } from './support/layoutQuality.js'
import { invoice, rework, parallel, partners } from './fixtures.js'
import { doc, lanes, node, flow } from './helpers.js'

const sample = () => doc({
  lanes: lanes('A', 'B'),
  nodes: [node('s', 'start_event', 'l1', 100, 90), node('t1', 'task', 'l1', 300, 90), node('t2', 'sub_process', 'l2', 520, 270), node('e', 'end_event', 'l2', 720, 270)],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 't2', { waypoints: [{ x: 1, y: 1 }] }), flow('f3', 't2', 'e')]
})
const byId = (d, id) => d.nodes.find((n) => n.id === id)

test('only activities resize', () => {
  assert.ok(isResizable({ type: 'user_task' }))
  assert.ok(isResizable({ type: 'sub_process' }))
  for (const type of ['start_event', 'exclusive_gateway', 'text_annotation', 'group', 'data_object']) {
    assert.equal(isResizable({ type }), false, type)
  }
  const d = sample()
  assert.equal(ops.resizeNode(d, 's', { width: 120, height: 120 }).doc, d, 'an event keeps its size')
})

test('resizeNode keeps the top-left corner, rounds, and drops the waypoints of its connections', () => {
  const d = sample()
  const before = byId(d, 't1')
  const next = ops.resizeNode(d, 't1', { width: 220.4, height: 90.6 }).doc
  const after = byId(next, 't1')
  assert.deepEqual([after.x, after.y, after.width, after.height], [before.x, before.y, 220, 91])
  assert.deepEqual(next.edges.find((e) => e.id === 'f2').waypoints, [])
})

test('resizeNode clamps to the limits; one side keeps the other', () => {
  const d = sample()
  const small = byId(ops.resizeNode(d, 't1', { width: 10, height: 10 }).doc, 't1')
  assert.deepEqual(nodeSize(small), MIN_NODE_SIZE)
  const big = byId(ops.resizeNode(d, 't1', { width: 5000, height: 5000 }).doc, 't1')
  assert.deepEqual(nodeSize(big), MAX_NODE_SIZE)
  const wider = byId(ops.resizeNode(d, 't1', { width: 200 }).doc, 't1')
  assert.deepEqual(nodeSize(wider), { width: 200, height: 64 })
})

test('Auto writes null, so the box takes its type default again', () => {
  const resized = ops.resizeNode(sample(), 't2', { width: 260, height: 100 }).doc
  const auto = ops.resizeNode(resized, 't2', null).doc
  const t2 = byId(auto, 't2')
  assert.equal(t2.width, null)
  assert.equal(t2.height, null)
  assert.deepEqual(nodeSize(t2), { width: 150, height: 64 })
  assert.equal(ops.resizeNode(auto, 't2', null).doc, auto, 'already Auto: nothing to commit')
  assert.equal(ops.resizeNode(auto, 't2', { width: 150, height: 64 }).doc, auto, 'its own default size: still Auto')
  const saved = forSave(auto).nodes.find((n) => n.id === 't2')
  assert.ok('width' in saved && saved.width === null, 'the save carries the null')
})

test('a node taller than its lane grows the lane and carries the next lanes along', () => {
  const d = sample()
  const next = ops.resizeNode(d, 't1', { width: 150, height: 200 }).doc
  const layout = layoutLanes(next)
  assert.ok(layout.byId.get('l1').size > 180)
  for (const n of next.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
  assert.ok(byId(next, 't2').y > byId(d, 't2').y, 'lane B moved down with its nodes')
})

test('the name, the badge tab and the [+] follow the resized box', () => {
  const t2 = { ...byId(sample(), 't2'), x: 0, y: 0, width: 300, height: 120 }
  const label = insideLabelBox(t2)
  assert.equal(label.w, 300 - 16)
  assert.equal(label.h, 120 - 4 - markerZone(120).height - 1)
  assert.ok(label.lines > insideLabelBox({ ...t2, height: null }).lines)
  const tab = badgeTabBox(t2, 'x'.repeat(60))
  assert.equal(tab.w, 300, 'a long badge reaches the wider box edge')
  assert.equal(tab.radius, 12)
})

test('connections end on the resized box', () => {
  const next = ops.resizeNode(sample(), 't1', { width: 260, height: 100 }).doc
  const box = nodeBox(byId(next, 't1'))
  const f1 = routeAll(next).get('f1').points
  const end = f1[f1.length - 1]
  assert.ok(Math.abs(end.x - box.x) < 0.5 || Math.abs(end.y - box.y) < 0.5, `f1 ends on the box edge: ${JSON.stringify(end)} vs ${JSON.stringify(box)}`)
})

// A sheet this small makes compact mode tighten the flow, which narrows the
// activities that have no width of their own.
const TINY_PAGE = { width: 2, height: 2, orientation: 'landscape' }

test('Tidy up keeps a size of its own and makes room for it', () => {
  const resized = ops.resizeNode(sample(), 't1', { width: 260, height: 100 }).doc
  for (const options of [{ mode: 'straight' }, { mode: 'compact', page: TINY_PAGE }]) {
    const laid = autoLayout(resized, options)
    assert.deepEqual(nodeSize(byId(laid, 't1')), { width: 260, height: 100 }, options.mode)
    const flowNodes = laid.nodes.map(nodeBox)
    flowNodes.forEach((a, i) => flowNodes.slice(i + 1).forEach((b) => assert.equal(boxesOverlap(a, b), false, `${options.mode}: no overlap`)))
  }
  assert.equal(nodeSize(byId(autoLayout(resized, { mode: 'compact', page: TINY_PAGE }), 't2')).width, 110, 'an Auto activity is narrowed')
})

test('the BPMN XML carries the resized bounds', () => {
  const next = ops.resizeNode(sample(), 't1', { width: 260, height: 100 }).doc
  const t1 = byId(next, 't1')
  assert.match(toBpmnXml(next), new RegExp(`bpmnElement="[^"]*t1"[^>]*>\\s*<dc:Bounds x="${t1.x}" y="${t1.y}" width="260" height="100"`))
})

// Seeded runs of resizes on the sample flows, each settled by the local
// arrangement as the editor settles it: no hard layout constraint breaks.
test('resizing any activity keeps the layout clean', () => {
  let state = 7
  const random = () => { state = (state * 48271) % 2147483647; return state / 2147483647 }
  for (const [name, fixture] of Object.entries({ invoice, rework, parallel, partners })) {
    let d = autoLayout(normalize(fixture()), { mode: 'straight' })
    for (let step = 0; step < 12; step++) {
      const activities = d.nodes.filter(isResizable)
      const target = activities[Math.floor(random() * activities.length)]
      const size = random() < 0.2 ? null : { width: 80 + Math.round(random() * 300), height: 40 + Math.round(random() * 140) }
      const result = ops.resizeNode(d, target.id, size)
      d = arrange(result.doc, { before: d })
      const m = measure(d)
      assert.equal(m.hard, 0, `${name}, step ${step} (${target.id} → ${JSON.stringify(size)}): ${JSON.stringify(m.details)}`)
    }
  }
})
