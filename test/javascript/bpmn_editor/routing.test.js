import { test } from 'node:test'
import assert from 'node:assert/strict'
import { routeEdge, routeAll, autoSides } from '../../../app/components/bali/bpmn_editor/model/routing.js'
import { nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, node, flow } from './helpers.js'

const orthogonal = (points) => points.every((p, i) => i === 0 || p.x === points[i - 1].x || p.y === points[i - 1].y)
const crosses = (points, box) => points.some((p, i) => {
  if (!i) return false
  const a = points[i - 1]
  if (a.x === p.x) return a.x > box.x && a.x < box.x + box.w && Math.max(a.y, p.y) > box.y && Math.min(a.y, p.y) < box.y + box.h
  return a.y > box.y && a.y < box.y + box.h && Math.max(a.x, p.x) > box.x && Math.min(a.x, p.x) < box.x + box.w
})

test('a target further along leaves right and enters left', () => {
  const a = nodeBox(node('a', 'task', null, 100, 100))
  const b = nodeBox(node('b', 'task', null, 400, 100))
  assert.deepEqual(autoSides(a, b), ['right', 'left'])
  const route = routeEdge(flow('e', 'a', 'b'), a, b)
  assert.deepEqual(route.points, [{ x: 175, y: 100 }, { x: 325, y: 100 }])
})

test('the route goes around an element in the way', () => {
  const a = nodeBox(node('a', 'task', null, 100, 100))
  const blocker = nodeBox(node('x', 'task', null, 300, 100))
  const b = nodeBox(node('b', 'task', null, 500, 100))
  const route = routeEdge(flow('e', 'a', 'b'), a, b, [blocker])
  assert.ok(orthogonal(route.points))
  assert.equal(crosses(route.points, blocker), false)
})

test('a pinned port is respected', () => {
  const a = nodeBox(node('a', 'task', null, 100, 100))
  const b = nodeBox(node('b', 'task', null, 400, 300))
  const route = routeEdge(flow('e', 'a', 'b', { ports: { source: 'bottom', target: 'top' } }), a, b)
  assert.deepEqual(route.points[0], { x: 100, y: 132 })
  assert.deepEqual(route.points[route.points.length - 1], { x: 400, y: 268 })
  assert.equal(route.sourceSide, 'bottom')
})

test('waypoints from the document are drawn as they are', () => {
  const a = nodeBox(node('a', 'task', null, 100, 100))
  const b = nodeBox(node('b', 'task', null, 400, 100))
  const waypoints = [{ x: 175, y: 100 }, { x: 250, y: 100 }, { x: 250, y: 300 }]
  assert.deepEqual(routeEdge(flow('e', 'a', 'b', { waypoints }), a, b).points, waypoints)
})

test('the label rides on the longest segment', () => {
  const a = nodeBox(node('a', 'task', null, 100, 100))
  const b = nodeBox(node('b', 'task', null, 600, 100))
  assert.deepEqual(routeEdge(flow('e', 'a', 'b'), a, b).label, { x: 350, y: 100, vertical: false })
})

test('routeAll skips edges whose ends are missing and lets lines cross groups', () => {
  const d = doc({
    nodes: [node('a', 'task', null, 100, 100), node('b', 'task', null, 500, 100), node('g', 'group', null, 300, 100)],
    edges: [flow('e1', 'a', 'b'), flow('e2', 'a', 'gone')]
  })
  const routes = routeAll(d)
  assert.deepEqual([...routes.keys()], ['e1'])
  assert.equal(routes.get('e1').points.length, 2, 'straight through the group')
})

// One cold run measured 115 ms on a CI runner against ~23 ms locally: the first
// call pays for JIT warm-up and the runner is shared. The median of warm runs is
// what the editor pays on every edit (~11 ms locally).
test('routing sixty connections takes well under 100 ms', () => {
  const nodes = []
  const edges = []
  for (let i = 0; i < 61; i++) nodes.push(node(`n${i}`, 'task', null, 100 + (i % 12) * 200, 100 + Math.floor(i / 12) * 140))
  for (let i = 0; i < 60; i++) edges.push(flow(`e${i}`, `n${i}`, `n${i + 1}`))
  const diagram = doc({ nodes, edges })
  routeAll(diagram)
  const runs = []
  for (let i = 0; i < 5; i++) {
    const started = performance.now()
    routeAll(diagram)
    runs.push(performance.now() - started)
  }
  const median = runs.sort((a, b) => a - b)[2]
  assert.ok(median < 100, `median ${median.toFixed(1)} ms`)
})
