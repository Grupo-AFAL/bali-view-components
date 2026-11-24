import { test } from 'node:test'
import assert from 'node:assert/strict'
import { alignmentGuides } from '../../../app/components/bali/bpmn_editor/model/guides.js'
import { arrange } from '../../../app/components/bali/bpmn_editor/model/arrange.js'
import { nodeBox } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { doc, lanes, node, flow } from './helpers.js'

// t1 and t2 in a row of lane A, the gateway under t1 in lane B.
const diagram = (dragged) => doc({
  lanes: lanes('A', 'B'),
  nodes: [node('t1', 'task', 'l1', 300, 90), node('t2', 'task', 'l1', 560, 90), node('g', 'exclusive_gateway', 'l2', 300, 270), dragged],
  edges: [flow('f1', 't1', 't2')]
})
const at = (cx, cy) => node('d', 'task', 'l2', cx, cy)

test('no guide while the dragged element lines up with nothing', () => {
  assert.deepEqual(alignmentGuides(diagram(at(437, 252)), ['d']), [])
  assert.deepEqual(alignmentGuides(diagram(at(560, 270)), []), [], 'nothing dragged')
})

test('a vertical guide through the centres while the drop would share a column, from one element to the other', () => {
  const [guide, ...rest] = alignmentGuides(diagram(at(563, 233)), ['d'])
  assert.equal(rest.length, 0)
  assert.deepEqual(guide, { axis: 'x', x1: 560, x2: 560, y1: 90 - 32, y2: 233 + 32 })
})

test('a horizontal guide while the drop would share a row, across elements of different sizes', () => {
  const guides = alignmentGuides(diagram(at(700, 268)), ['d'])
  assert.deepEqual(guides, [{ axis: 'y', y1: 270, y2: 270, x1: 300 - 25, x2: 700 + 75 }])
})

test('both guides at once, and none against a group or against what is dragged along', () => {
  const both = alignmentGuides(diagram(at(558, 272)), ['d'])
  assert.deepEqual(both.map((g) => g.axis), ['x', 'y'])
  const withGroup = diagram(at(437, 252))
  withGroup.nodes.push({ id: 'grp', type: 'group', x: 437 - 120, y: 252 - 75, name: '' })
  assert.deepEqual(alignmentGuides(withGroup, ['d']), [])
  assert.deepEqual(alignmentGuides(diagram(at(560, 200)), ['d', 't2']).filter((g) => g.axis === 'x'), [], 'the element it shares a column with moves with it')
})

// What makes the guide true: half a grid step off the line or less, the drop lands on it.
test('the guide shows exactly when the arrangement will put the dropped centre on that line', () => {
  for (const cx of [552, 554, 556, 560, 564, 566, 568]) {
    const dropped = diagram(at(cx, 250))
    const shown = alignmentGuides(dropped, ['d']).some((g) => g.axis === 'x')
    const settled = nodeBox(arrange(dropped).nodes.find((n) => n.id === 'd')).cx
    assert.equal(shown, settled === 560, `dragged to ${cx}: guide ${shown}, dropped at ${settled}`)
  }
})
