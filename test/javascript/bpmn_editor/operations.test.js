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

test('appendNode adds the next element connected, in the chosen direction', () => {
  const d = twoLanes()
  d.nodes.push(node('g', 'exclusive_gateway', 'l1', 450, 90, { name: 'Valid?' }))
  d.edges = d.edges.filter((e) => e.id !== 'f2').concat(flow('fg', 't1', 'g'))
  const { doc: next, id } = ops.appendNode(d, 'g', { type: 'end_event' }, 'right', { labels: { yes: 'Yes', no: 'No' } })
  const created = byId(next, id)
  assert.ok(nodeBox(created).cx > nodeBox(byId(d, 'g')).cx)
  assert.equal(created.lane_id, 'l1')
  assert.deepEqual(next.edges.at(-1), { id: next.edges.at(-1).id, source: 'g', target: id, label: 'Yes' })
})

test('appendNode moves the following nodes along when the spot ahead is taken', () => {
  const d = twoLanes()
  d.edges = d.edges.filter((e) => e.id !== 'f2')
  d.nodes.push(node('t9', 'task', 'l1', 470, 90, { name: 'Next' }))
  const before = nodeBox(byId(d, 't9')).cx
  const { doc: next } = ops.appendNode(d, 't1', { type: 'task' }, 'right')
  assert.ok(nodeBox(byId(next, 't9')).cx > before, 'the node ahead moved')
})

test('appendNode is blocked where there is no room and where the connection is not allowed', () => {
  const d = twoLanes()
  assert.equal(ops.appendNode(d, 't1', { type: 'task' }, 'right').error, 'block_connection', 't1 already has its outgoing flow')
  d.edges = d.edges.filter((e) => e.id !== 'f2')
  assert.equal(ops.appendNode(d, 's', { type: 'task' }, 'left').error, 'block_no_space', 'into the header')
  assert.equal(ops.appendNode(d, 'e', { type: 'task' }, 'right').error, 'block_end_source')
})

// Lanes fitted to their content leave no band beyond the first or last one:
// the edge lane grows instead of the edit being refused.
test('appendNode across the flow past the first or the last lane grows that lane', () => {
  const d = twoLanes()
  d.edges = d.edges.filter((e) => e.id !== 'f2' && e.id !== 'f3')
  const down = ops.appendNode(d, 't2', { type: 'task' }, 'down')
  assert.equal(down.error, undefined)
  const below = byId(down.doc, down.id)
  assert.equal(below.lane_id, 'l2')
  assert.ok(nodeBox(below).cy > nodeBox(byId(d, 't2')).cy)
  assert.ok(insideLane(layoutLanes(down.doc), below), 'inside its lane')
  const up = ops.appendNode(d, 't1', { type: 'task' }, 'up')
  assert.equal(up.error, undefined)
  const above = byId(up.doc, up.id)
  assert.equal(above.lane_id, 'l1')
  assert.ok(nodeBox(above).cy < nodeBox(byId(up.doc, 't1')).cy)
  assert.ok(up.doc.nodes.every((n) => insideLane(layoutLanes(up.doc), n)), 'everything still inside its lane')
})

test('insertOnEdge splits a flow without disconnecting anything and moves the rest along', () => {
  const d = twoLanes()
  const before = nodeBox(byId(d, 't2')).cx
  const { doc: next, id } = ops.insertOnEdge(d, 'f1', { type: 'task' }, { x: 180, y: 90 })
  const ids = next.edges.map((e) => [e.source, e.target])
  assert.ok(ids.some(([s, t]) => s === 's' && t === id))
  assert.ok(ids.some(([s, t]) => s === id && t === 't1'))
  assert.ok(nodeBox(byId(next, 't1')).cx > nodeBox(byId(d, 't1')).cx)
  assert.ok(nodeBox(byId(next, 't2')).cx > before)
  for (const n of next.nodes) assert.ok(insideLane(layoutLanes(next), n), `${n.id} inside its lane`)
})

test('alignNodes lines up across lanes on the flow axis, and only inside a lane across it', () => {
  const d = twoLanes()
  const column = ops.alignNodes(d, ['t1', 't2'], 'vertical').doc
  assert.equal(nodeBox(byId(column, 't1')).cx, nodeBox(byId(column, 't2')).cx)
  assert.equal(byId(column, 't2').lane_id, 'l2')
  assert.equal(ops.alignNodes(d, ['t1', 't2'], 'horizontal').error, 'block_align_horizontal')
  const row = ops.alignNodes(d, ['s', 't1'], 'horizontal').doc
  assert.equal(nodeBox(byId(row, 's')).cy, nodeBox(byId(row, 't1')).cy)
})

test('insertOnEdge refuses a start or end event and keeps the edge id on the first half', () => {
  assert.equal(ops.insertOnEdge(twoLanes(), 'f1', { type: 'end_event' }, { x: 180, y: 90 }).error, 'block_end_source')
  assert.equal(ops.insertOnEdge(twoLanes(), 'f1', { type: 'start_event' }, { x: 180, y: 90 }).error, 'block_start_target')
  const { doc: next, id } = ops.insertOnEdge(twoLanes(), 'f1', { type: 'task' }, { x: 180, y: 90 })
  assert.deepEqual(next.edges.find((e) => e.id === 'f1'), { id: 'f1', source: 's', target: id, ports: { source: 'auto', target: 'auto' }, waypoints: [] })
})

test('deleting a lane clears the waypoints of the nodes it moves', () => {
  const added = ops.addLane(twoLanes(), { name: 'C' })
  const d = ops.reorderLanes(added.doc, [added.id, 'l1', 'l2']).doc
  d.edges[2].waypoints = [{ x: 1, y: 1 }, { x: 2, y: 2 }]
  const removed = ops.deleteElements(d, { laneIds: [added.id] }).doc
  assert.deepEqual(removed.edges[2].waypoints, [])
  assert.deepEqual(removed.nodes.map((n) => n.y), twoLanes().nodes.map((n) => n.y), 'nodes back where they were')
})

test('aligning never pushes a node into the lane header', () => {
  const d = doc({ lanes: lanes('A', 'B'), nodes: [node('s', 'start_event', 'l1', 72, 90), node('t', 'task', 'l2', 129, 270)] })
  assert.equal(ops.alignNodes(d, ['s', 't'], 'vertical').error, 'block_lane')
})

test('a sequence flow does not cross into an external participant', () => {
  const d = twoLanes()
  d.lanes[1].kind = 'external'
  d.edges = d.edges.filter((e) => e.id !== 'f2')
  assert.equal(ops.connectionError(d, 't1', 't2'), 'block_sequence_participants')
  assert.equal(ops.connectionError(d, 't1', 't2', { type: 'message_flow' }), null)
})

// The user's case: "Record payment" already goes up to a new activity; the
// quick menu asked for one more to the right.
const recordPayment = () => doc({
  lanes: lanes('Accounts payable', 'Treasury'),
  nodes: [node('t3', 'task', 'l2', 300, 270, { name: 'Record payment' }), node('up', 'task', 'l1', 300, 90, { name: 'New activity' })],
  edges: [flow('f5', 't3', 'up')]
})

test('a second way out of an activity is a split: a gateway after it, the existing way through it, the new element as its second branch', () => {
  const d = recordPayment()
  assert.equal(ops.appendNode(d, 't3', { type: 'task' }, 'right').error, 'block_connection', 'R02 still holds')
  assert.deepEqual(ops.branchPoint(d, 't3'), { edge: d.edges[0], split: null })
  assert.equal(ops.branchNode(d, 't3', { type: 'task' }, 'right').error, 'block_needs_gateway')

  const { doc: next, id, gatewayId } = ops.branchNode(d, 't3', { type: 'task' }, 'right', { gateway: 'exclusive_gateway', labels: { yes: 'Yes', no: 'No' } })
  const gateway = byId(next, gatewayId)
  assert.equal(gateway.type, 'exclusive_gateway')
  const pairs = next.edges.map((e) => [e.source, e.target])
  assert.deepEqual(pairs.filter(([s]) => s === 't3'), [['t3', gatewayId]], 'the activity keeps one way out')
  assert.ok(pairs.some(([s, t]) => s === gatewayId && t === 'up'), 'the existing way passes through the gateway')
  assert.ok(pairs.some(([s, t]) => s === gatewayId && t === id), 'the new element is a branch')
  assert.ok(nodeBox(byId(next, id)).cx > nodeBox(gateway).cx, 'in the direction asked for')
  assert.ok(next.edges.filter((e) => e.source === gatewayId).every((e) => !e.label), 'branches of a new gateway are left to be named (R03)')
})

test('when the way out already leads to a splitting gateway, the new element is one more branch of it', () => {
  const d = recordPayment()
  const first = ops.branchNode(d, 't3', { type: 'task' }, 'right', { gateway: 'parallel_gateway' })
  const again = ops.branchNode(first.doc, 't3', { type: 'end_event' }, 'down', { gateway: 'exclusive_gateway' })
  assert.equal(again.gatewayId, first.gatewayId)
  assert.equal(again.doc.nodes.filter((n) => n.type.endsWith('_gateway')).length, 1, 'no second gateway')
  assert.equal(again.doc.edges.filter((e) => e.source === first.gatewayId).length, 3)
})

test('a connection refused for that reason can be made through a gateway', () => {
  const d = recordPayment()
  d.nodes.push(node('e', 'end_event', 'l2', 600, 270))
  assert.equal(ops.connectionError(d, 't3', 'e'), 'block_connection')
  const { doc: next, gatewayId } = ops.connectThroughGateway(d, 't3', 'e')
  assert.ok(next.edges.some((e) => e.source === gatewayId && e.target === 'e'))
  assert.ok(next.edges.some((e) => e.source === gatewayId && e.target === 'up'))
})
