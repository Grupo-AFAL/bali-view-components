import { test } from 'node:test'
import assert from 'node:assert/strict'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { layoutLanes, nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { LETTER } from '../../../app/components/bali/bpmn_editor/model/page.js'

// What an app that stores no geometry sends, for the editor's document and
// for a `compare_with:` one alike: lanes with only id, name, kind and order,
// no coordinates, and the start and end events in no lane.
function withoutGeometry () {
  const lanes = [1, 2, 3, 4].map((order) => ({ id: `l${order}`, name: `Lane ${order}`, kind: 'internal', order }))
  const steps = ['t1', 't2', 't3', 'g', 't4', 't5', 't6', 't7', 't8', 't9', 't10']
  const nodes = [
    { id: 's', type: 'start_event', name: 'Start' },
    ...steps.map((id, i) => ({ id, type: id === 'g' ? 'exclusive_gateway' : 'task', name: id, lane_id: `l${(i % 4) + 1}` })),
    { id: 'e', type: 'end_event', name: 'End' }
  ]
  const ids = nodes.map((n) => n.id)
  const edges = ids.slice(1).map((id, i) => ({ id: `f${i}`, source: ids[i], target: id }))
  return { lanes, nodes, edges }
}

const COMPACT = { mode: 'compact', page: LETTER }
const laneAtCenter = (layout, node) => {
  const box = nodeBox(node)
  const middle = box.y + box.h / 2
  const entry = layout.entries.find((e) => middle >= e.offset && middle < e.offset + e.size)
  return entry ? String(entry.id) : null
}

test('a document without geometry is laid out in its lanes, the events without a lane in the first one', () => {
  const doc = normalize(withoutGeometry(), COMPACT)
  const layout = layoutLanes(doc)

  assert.deepEqual(layout.entries.map((e) => String(e.id)), ['l1', 'l2', 'l3', 'l4'])
  for (const node of doc.nodes) assert.equal(laneAtCenter(layout, node), node.lane_id || 'l1', node.id)
  assert.ok(new Set(doc.nodes.map((n) => n.y)).size > 1, 'not one row')
})

// The editor passes the component's `layout:` / `page:` to every normalize —
// on load, a server answer, and each `compare_with:` document — because
// autoLayout's own default is another layout.
test('the layout options decide the layout of a document without geometry', () => {
  const compact = layoutLanes(normalize(withoutGeometry(), COMPACT))
  const fallback = layoutLanes(normalize(withoutGeometry()))
  assert.notEqual(compact.length, fallback.length)
})
