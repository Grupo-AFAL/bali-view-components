import { test } from 'node:test'
import assert from 'node:assert/strict'
import { autoLayout, needsLayout } from '../../../app/components/bali/bpmn_editor/model/layout.js'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { layoutLanes, insideLane, nodeBox, boxesOverlap } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, lanes, flow } from './helpers.js'

const unplaced = (id, type, laneId) => ({ id, type, lane_id: laneId, name: id })

function chain () {
  return doc({
    lanes: lanes('A', 'B'),
    nodes: [unplaced('s', 'start_event', 'l1'), unplaced('t1', 'task', 'l1'), unplaced('g', 'exclusive_gateway', 'l1'),
      unplaced('t2', 'task', 'l2'), unplaced('t3', 'task', 'l1'), unplaced('e', 'end_event', 'l2')],
    edges: [flow('f1', 's', 't1'), flow('f2', 't1', 'g'), flow('f3', 'g', 't2'), flow('f4', 'g', 't3'), flow('f5', 't2', 'e'), flow('f6', 't3', 'e'), flow('back', 't3', 't1')]
  })
}

test('a document without coordinates is laid out on load', () => {
  assert.equal(needsLayout(chain()), true)
  const laid = normalize(chain())
  assert.equal(needsLayout(laid), false)
})

test('the main path reads along the flow axis, loops ignored', () => {
  const laid = autoLayout(chain())
  const x = (id) => nodeBox(laid.nodes.find((n) => n.id === id)).cx
  assert.ok(x('s') < x('t1') && x('t1') < x('g') && x('g') < x('t2') && x('t2') < x('e'))
})

test('every node stays in its lane, inside it, without overlapping', () => {
  const laid = autoLayout(chain())
  const layout = layoutLanes(laid)
  for (const n of laid.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
  for (const a of laid.nodes) {
    for (const b of laid.nodes) if (a !== b) assert.equal(boxesOverlap(nodeBox(a), nodeBox(b)), false, `${a.id}/${b.id}`)
  }
  assert.equal(laid.nodes.find((n) => n.id === 't2').lane_id, 'l2')
})

test('vertical documents flow down', () => {
  const laid = autoLayout({ ...chain(), orientation: 'vertical' })
  const y = (id) => nodeBox(laid.nodes.find((n) => n.id === id)).cy
  assert.ok(y('s') < y('t1') && y('t1') < y('e'))
  const layout = layoutLanes(laid)
  for (const n of laid.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
})

test('connections go back to automatic routing', () => {
  const d = chain()
  d.edges[0].ports = { source: 'top', target: 'top' }
  d.edges[0].waypoints = [{ x: 1, y: 1 }]
  const laid = autoLayout(d)
  assert.deepEqual(laid.edges[0].ports, { source: 'auto', target: 'auto' })
  assert.deepEqual(laid.edges[0].waypoints, [])
})
