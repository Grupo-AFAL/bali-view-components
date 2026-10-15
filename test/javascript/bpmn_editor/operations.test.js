import { test } from 'node:test'
import assert from 'node:assert/strict'
import * as ops from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { layoutLanes, insideLane, nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, lanes, node, flow } from './helpers.js'

const twoLanes = () => doc({
  lanes: lanes('A', 'B'),
  nodes: [node('s', 'start_event', 'l1', 100, 90), node('t1', 'task', 'l1', 260, 90), node('t2', 'task', 'l2', 460, 270), node('e', 'end_event', 'l2', 660, 270)],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 't2'), flow('f3', 't2', 'e')]
})
const byId = (d, id) => d.nodes.find((n) => n.id === id)

test('createNode places the node in the lane under the point, named by family', () => {
  const { doc: d, id } = ops.createNode(twoLanes(), { type: 'task' }, { x: 460, y: 90 }, { names: { task: 'New activity' } })
  const created = byId(d, id)
  assert.equal(created.lane_id, 'l1')
  assert.equal(created.name, 'New activity')
  assert.ok(insideLane(layoutLanes(d), created))
})

test('createNode is blocked outside every lane and on top of another element', () => {
  assert.equal(ops.createNode(twoLanes(), { type: 'task' }, { x: 400, y: 900 }).error, 'block_lane')
  assert.equal(ops.createNode(twoLanes(), { type: 'task' }, { x: 270, y: 95 }).error, 'block_overlap')
  assert.ok(ops.createNode(twoLanes(), { type: 'task' }, { x: 270, y: 95 }, { policy: { ...ops.DEFAULT_POLICY, noOverlap: false } }).doc)
})

test('a node that does not fit makes its lane grow and carries the next lanes along', () => {
  const { doc: d } = ops.createNode(twoLanes(), { type: 'task' }, { x: 460, y: 170 })
  const layout = layoutLanes(d)
  assert.ok(layout.byId.get('l1').size > 180, 'lane A grew')
  assert.equal(byId(d, 't2').y, byId(twoLanes(), 't2').y + layout.byId.get('l1').size - 180, 'lane B nodes moved with it')
  for (const n of d.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
})

test('moveNodes changes lane by the centre and blocks overlap and the header', () => {
  const moved = ops.moveNodes(twoLanes(), ['t1'], { x: 600, y: 180 }).doc
  assert.equal(byId(moved, 't1').lane_id, 'l2')
  assert.equal(ops.moveNodes(twoLanes(), ['t1'], { x: 200, y: 180 }).error, 'block_overlap')
  assert.equal(ops.moveNodes(twoLanes(), ['t1'], { x: -230, y: 0 }).error, 'block_lane')
  assert.equal(ops.moveNodes(twoLanes(), ['t1'], { x: 0, y: 900 }).error, 'block_lane')
})

test('moving clears the manual waypoints of the connections it touches', () => {
  const d = twoLanes()
  d.edges[1].waypoints = [{ x: 0, y: 0 }, { x: 1, y: 1 }]
  assert.deepEqual(ops.moveNodes(d, ['t1'], { x: 20, y: 0 }).doc.edges[1].waypoints, [])
})

test('one-in, one-out: an activity takes a single sequence flow each way', () => {
  const d = twoLanes()
  assert.equal(ops.connectionError(d, 't1', 'e'), 'block_connection', 'second outgoing')
  assert.equal(ops.connectionError(d, 's', 't2'), 'block_connection', 'second incoming')
  assert.equal(ops.connectionError(d, 't1', 'e', { policy: { ...ops.DEFAULT_POLICY, oneInOneOut: false } }), null)
})

test('connections refuse self, duplicates, a start as target and an end as source', () => {
  const d = twoLanes()
  assert.equal(ops.connectionError(d, 't1', 't1'), 'block_self')
  assert.equal(ops.connectionError(d, 's', 't1'), 'block_duplicate')
  assert.equal(ops.connectionError(d, 'e', 't1'), 'block_end_source')
  d.nodes.push(node('g', 'exclusive_gateway', 'l1', 600, 90))
  assert.equal(ops.connectionError(d, 'g', 's'), 'block_start_target')
})

test('message flows join different participants; associations need an artifact', () => {
  const d = twoLanes()
  d.lanes[1].kind = 'external'
  d.nodes.push(node('a', 'text_annotation', 'l1', 600, 60))
  assert.equal(ops.connectionError(d, 't1', 's', { type: 'message_flow' }), 'block_message_flow')
  assert.equal(ops.connectionError(d, 't1', 't2', { type: 'message_flow' }), null)
  assert.equal(ops.connectionError(d, 't1', 't2', { type: 'association' }), 'block_association')
  assert.equal(ops.connectionError(d, 'a', 't1', { type: 'association' }), null)
  assert.equal(ops.connectionError(d, 'a', 't1'), 'block_artifact_flow')
})

test('an exclusive gateway labels its first branches Yes and No', () => {
  let d = twoLanes()
  d.nodes.push(node('g', 'exclusive_gateway', 'l1', 600, 90), node('x', 'end_event', 'l1', 800, 90), node('y', 'end_event', 'l2', 800, 300), node('z', 'end_event', 'l1', 900, 150))
  const labels = { yes: 'Sí', no: 'No' }
  d = ops.connect(d, 'g', 'x', { labels }).doc
  d = ops.connect(d, 'g', 'y', { labels }).doc
  d = ops.connect(d, 'g', 'z', { labels }).doc
  assert.deepEqual(d.edges.slice(-3).map((e) => e.label ?? ''), ['Sí', 'No', ''])
})

test('reconnect moves one end and resets its port', () => {
  const d = twoLanes()
  d.edges[2].ports = { source: 'bottom', target: 'top' }
  const moved = ops.reconnect(d, 'f3', { target: 't1' }, { policy: { ...ops.DEFAULT_POLICY, oneInOneOut: false } }).doc
  assert.equal(moved.edges[2].target, 't1')
  assert.deepEqual(moved.edges[2].ports, { source: 'bottom', target: 'auto' })
  assert.equal(ops.reconnect(d, 'f3', { target: 't1' }).error, 'block_connection')
})

test('a lane with elements is not deleted and the minimum of lanes holds', () => {
  const d = twoLanes()
  assert.equal(ops.deleteElements(d, { laneIds: ['l2'] }).error, 'block_lane_has_nodes')
  const three = ops.addLane(d, { name: 'C' }).doc
  const laneC = three.lanes[2].id
  assert.ok(ops.deleteElements(three, { laneIds: [laneC] }).doc)
  assert.deepEqual(ops.deleteElements(d, { nodeIds: ['t2', 'e'], laneIds: ['l2'] }), { error: 'block_min_lanes', vars: { count: 2 } })
})

test('deleting a lane closes the gap and deleting a node removes its connections', () => {
  const d = ops.addLane(twoLanes(), { name: 'C' }).doc
  const cId = d.lanes[2].id
  const withNode = ops.createNode(d, { type: 'task' }, { x: 300, y: 450 }).doc
  const removed = ops.deleteElements(withNode, { laneIds: ['l2'], nodeIds: ['t2', 'e'] }).doc
  const moved = removed.nodes.find((n) => n.lane_id === cId)
  assert.ok(insideLane(layoutLanes(removed), moved), 'nodes of the lane after it moved back')
  assert.deepEqual(removed.edges.map((e) => e.id), ['f1'])
})

test('reorderLanes carries every node with its lane', () => {
  const d = ops.reorderLanes(twoLanes(), ['l2', 'l1']).doc
  const layout = layoutLanes(d)
  assert.deepEqual(layout.entries.map((e) => e.id), ['l2', 'l1'])
  for (const n of d.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
})

test('resizeLane never shrinks a lane below its content', () => {
  const d = ops.resizeLane(twoLanes(), 'l1', 40).doc
  assert.ok(layoutLanes(d).byId.get('l1').size >= nodeBox(byId(d, 't1')).y + 64)
})

test('setOrientation keeps every node in its lane, in reading order', () => {
  const d = ops.setOrientation(twoLanes(), 'vertical').doc
  const layout = layoutLanes(d)
  assert.equal(d.orientation, 'vertical')
  for (const n of d.nodes) assert.ok(insideLane(layout, n), `${n.id} inside its lane`)
  assert.ok(nodeBox(byId(d, 's')).cy < nodeBox(byId(d, 't1')).cy)
  const back = ops.setOrientation(d, 'horizontal').doc
  for (const n of back.nodes) assert.ok(insideLane(layoutLanes(back), n), `${n.id} back inside`)
})

test('movePool only moves the pool origin', () => {
  const d = ops.movePool(twoLanes(), 40, -10).doc
  assert.deepEqual(d.pool, { x: 40, y: -10 })
  assert.deepEqual(d.nodes, twoLanes().nodes)
})
