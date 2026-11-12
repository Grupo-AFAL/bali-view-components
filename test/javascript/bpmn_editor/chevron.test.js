import { test } from 'node:test'
import assert from 'node:assert/strict'
import { activityShapeOf, nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { insideLabelBox, badgeBox, badgeTabBox, taskMarkerAt, chevronDepth } from '../../../app/components/bali/bpmn_editor/model/labels.js'
import { routeAfresh, routeDiagram, portPoint, sameRouting } from '../../../app/components/bali/bpmn_editor/model/router.js'
import { quickRouteAll } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { doc, lanes, node, flow } from './helpers.js'

// Two activities in a row: the connection leaves A by its right side and
// enters B by its left one, at mid-height.
const row = (overrides = {}) => doc({
  lanes: lanes('Board'),
  nodes: [node('a', 'task', 'l1', 200, 90), node('b', 'sub_process', 'l1', 500, 90)],
  edges: [flow('e1', 'a', 'b')],
  ...overrides
})

test('a document draws cards unless it says chevron', () => {
  assert.equal(activityShapeOf(doc()), 'card')
  assert.equal(activityShapeOf(doc({ activity_shape: 'hexagon' })), 'card')
  assert.equal(activityShapeOf(doc({ activity_shape: 'chevron' })), 'chevron')
})

test("a connection ends in a chevron's notch and starts at its point", () => {
  const diagram = row({ activity_shape: 'chevron' })
  const points = routeAfresh(diagram).get('e1').points
  const a = nodeBox(diagram.nodes[0])
  const b = nodeBox(diagram.nodes[1])

  assert.deepEqual(points[0], { x: a.x + a.w, y: a.cy }, 'from the point, which reaches the box')
  assert.deepEqual(points[points.length - 1], { x: b.x + chevronDepth(b.h), y: b.cy }, 'into the notch')
})

test('a card is entered at its box', () => {
  const diagram = row()
  const points = routeAfresh(diagram).get('e1').points
  const b = nodeBox(diagram.nodes[1])

  assert.equal(points[points.length - 1].x, b.x)
})

test("a port off a chevron's middle follows its slanted sides", () => {
  const n = node('a', 'task', 'l1', 200, 90)
  const box = nodeBox(n)
  const d = chevronDepth(box.h)
  const offset = box.h / 4

  assert.equal(portPoint(n, box, 'left', offset, 'chevron').x, box.x + d / 2)
  assert.equal(portPoint(n, box, 'right', offset, 'chevron').x, box.x + box.w - d / 2)
  assert.equal(portPoint(n, box, 'top', 0, 'chevron').y, box.y, 'the top edge is straight')
  const event = node('s', 'start_event', 'l1', 60, 90)
  assert.deepEqual(portPoint(event, nodeBox(event), 'right', 0, 'chevron'), portPoint(event, nodeBox(event), 'right', 0), 'only activities')
})

test('the same diagram in the other shape routes again', () => {
  const card = row()
  const chevron = { ...card, activity_shape: 'chevron' }

  assert.equal(sameRouting(card, chevron), false)
  routeDiagram(card)
  const points = routeDiagram(chevron).get('e1').points
  assert.equal(points[points.length - 1].x, nodeBox(chevron.nodes[1]).x + chevronDepth(64))
})

test("a chevron's name keeps clear of its notch and point", () => {
  const n = node('a', 'user_task', 'l1', 200, 90, { width: 150, height: 64 })
  const card = insideLabelBox(n)
  const chevron = insideLabelBox(n, { activityShape: 'chevron' })
  const d = chevronDepth(64)

  assert.equal(chevron.x, card.x + d)
  assert.equal(chevron.w, card.w - d * 2)
  assert.equal(chevron.lines, card.lines)
  // The marker's foot stays inside the notch's slant: at y the notch is d·y/(h/2) in.
  const marker = taskMarkerAt(64, false, 'chevron')
  assert.ok(marker.x > d * (marker.y + marker.size) / 32, `marker at ${marker.x}`)
})

test("the pending marker sits on a chevron's top edge, not past it", () => {
  const n = node('a', 'task', 'l1', 200, 90)
  const box = nodeBox(n)

  assert.equal(badgeBox(n, 'chevron').x, badgeBox(n).x - chevronDepth(box.h))
  const gateway = node('g', 'exclusive_gateway', 'l1', 400, 90)
  assert.deepEqual(badgeBox(gateway, 'chevron'), badgeBox(gateway), 'only activities')
})

test("an app's badge stops where a chevron's top edge ends", () => {
  const n = node('a', 'task', 'l1', 200, 90)
  const long = 'A badge far longer than the activity is wide'

  assert.equal(badgeTabBox(n, long, { activityShape: 'chevron' }).w, badgeTabBox(n, long).w - chevronDepth(64))
})

test('a connection dragged into a chevron already ends in its notch', () => {
  const diagram = row({ activity_shape: 'chevron' })
  const points = quickRouteAll(diagram).get('e1').points
  const b = nodeBox(diagram.nodes[1])

  assert.deepEqual(points[points.length - 1], { x: b.x + chevronDepth(b.h), y: b.cy })
  assert.equal(quickRouteAll(row()).get('e1').points.at(-1).x, b.x, 'a card at its box')
})

test('a tall, narrow chevron keeps its notch short of its point and its name a width', () => {
  const n = node('a', 'task', 'l1', 200, 300, { width: 80, height: 400 })
  const box = nodeBox(n)
  const d = chevronDepth(box.h, box.w)

  assert.ok(1 + d < box.w - 1 - d, `notch at ${1 + d}, point at ${box.w - 1}`)
  assert.ok(insideLabelBox(n, { activityShape: 'chevron' }).w > 0)
  const port = portPoint(n, box, 'left', 0, 'chevron')
  assert.ok(port.x >= box.x && port.x <= box.x + box.w, 'the connection ends on the shape')
})
