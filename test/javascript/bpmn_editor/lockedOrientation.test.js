import { test } from 'node:test'
import assert from 'node:assert/strict'
import { normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { load, loadAnswer } from '../../../app/components/bali/bpmn_editor/model/load.js'
import { layoutLanes } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { setOrientation } from '../../../app/components/bali/bpmn_editor/model/operations.js'
import { LETTER } from '../../../app/components/bali/bpmn_editor/model/page.js'
import { doc, lanes, node, flow } from './helpers.js'

// Component `lock_orientation: :vertical` reaches every load as
// `layoutOptions.orientation`: the first one, each 200 and the comparison.
const locked = (orientation) => ({ mode: 'compact', page: LETTER, orientation })
const stored = () => doc({
  lanes: lanes('Board', 'Treasury'),
  nodes: [node('a', 'task', 'l1', 200, 90), node('b', 'task', 'l2', 500, 250)],
  edges: [flow('e1', 'a', 'b')]
})

test('a document drawn the other way is turned as the switch would turn it', () => {
  const turned = load(stored(), locked('vertical'))

  assert.equal(turned.orientation, 'vertical')
  assert.equal(layoutLanes(turned).orientation, 'vertical')
  assert.deepEqual(turned, normalize(setOrientation(stored(), 'vertical').doc), 'the same as the toolbar')
})

test('a document already in that orientation is left as it is', () => {
  const vertical = normalize(setOrientation(stored(), 'vertical').doc)

  assert.deepEqual(load(vertical, locked('vertical')), vertical)
  assert.deepEqual(load(stored(), locked('horizontal')), normalize(stored()))
})

test('a document without coordinates is laid out in that orientation', () => {
  const bare = { lanes: [{ id: 'l1', name: 'Board' }], nodes: [{ id: 't', type: 'task', name: 'Plan', lane_id: 'l1' }], edges: [] }

  assert.equal(load(bare, locked('vertical')).orientation, 'vertical')
  assert.equal(load(bare, { mode: 'compact', page: LETTER }).orientation, 'horizontal')
})

test('a 200 that leaves the orientation out is the vertical document the island sent, not turned again', () => {
  const sent = load(stored(), locked('vertical'))
  const answer = { ...sent }
  delete answer.orientation

  assert.deepEqual(loadAnswer(answer, locked('vertical')), sent)
  assert.equal(loadAnswer(answer, { mode: 'compact', page: LETTER }).orientation, 'horizontal', 'unlocked, the contract reads it horizontal')
})
