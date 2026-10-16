import { test } from 'node:test'
import assert from 'node:assert/strict'
import { layoutLanes, laneAt, insideLane, laneRect, laneRequiredSize, HEADER, MIN_POOL_LENGTH } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, lanes, node } from './helpers.js'

test('lanes stack along the main axis in their order, not their array order', () => {
  const d = doc({ lanes: [{ id: 'b', order: 2, size: 100 }, { id: 'a', order: 1, size: 150 }] })
  const layout = layoutLanes(d)
  assert.deepEqual(layout.entries.map((e) => [e.id, e.offset, e.size]), [['a', 0, 150], ['b', 150, 100]])
  assert.equal(layout.thickness, 250)
})

test('vertical lanes stack along x and share the y length', () => {
  const layout = layoutLanes(doc({ orientation: 'vertical', lanes: lanes('A', 'B') }))
  assert.deepEqual(laneRect(layout, layout.entries[1]), { x: 180, y: 0, w: 180, h: layout.length })
  assert.equal(layout.header, HEADER.vertical)
})

test('the shared length follows the furthest node and never drops below the minimum', () => {
  assert.equal(layoutLanes(doc({ lanes: lanes('A') })).length, MIN_POOL_LENGTH.horizontal)
  const far = layoutLanes(doc({ lanes: lanes('A'), nodes: [node('n', 'task', 'l1', 2000, 90)] }))
  assert.ok(far.length >= 2075 + 100)
  assert.equal(layoutLanes(doc({ lanes: lanes('A'), pool: { length: 3000 } })).length, 3000)
})

test('laneAt finds the band a point falls in', () => {
  const layout = layoutLanes(doc({ lanes: lanes('A', 'B') }))
  assert.equal(laneAt(layout, { x: 300, y: 200 }).id, 'l2')
  assert.equal(laneAt(layout, { x: 300, y: 400 }), null)
})

test('insideLane requires the box inside the band and clear of the header', () => {
  const d = doc({ lanes: lanes('A', 'B') })
  const layout = layoutLanes(d)
  assert.equal(insideLane(layout, node('n', 'task', 'l1', 200, 90)), true)
  assert.equal(insideLane(layout, node('n', 'task', 'l1', 200, 170)), false, 'crosses into the next lane')
  assert.equal(insideLane(layout, node('n', 'task', 'l1', 60, 90)), false, 'sits on the header')
  assert.equal(insideLane(layout, node('n', 'task', 'gone', 200, 90)), false, 'unknown lane')
})

test('a lane needs room for the label under its events', () => {
  const d = doc({ lanes: lanes('A'), nodes: [node('e', 'end_event', 'l1', 200, 160)] })
  assert.ok(laneRequiredSize(d, layoutLanes(d), 'l1') >= 160 + 18 + 30)
})

test('a name gets the width the browser needs for it: 6.9 px a glyph measured, so no name is cut off', async () => {
  const { textBlock } = await import('../../../app/components/bali/bpmn_editor/model/labels.js')
  assert.ok(textBlock('Tiempo (captura)').w >= 16 * 6.9)
  assert.equal(textBlock('Tiempo (captura)').lines, 1)
  assert.equal(textBlock('Compensación (lanzamiento)').lines, 2, 'breaks at the space, as the browser does')
})
