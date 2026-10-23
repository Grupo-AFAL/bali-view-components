import { test } from 'node:test'
import assert from 'node:assert/strict'
import { openMode, requestedComparison, shownMode, DEFAULT_COMPARE_MODE } from '../../../app/components/bali/bpmn_editor/model/compare.js'

test('compare_open: true opens in the default view, a mode in that mode, anything else stays closed', () => {
  assert.equal(openMode('true'), DEFAULT_COMPARE_MODE)
  assert.equal(openMode(true), 'side_by_side')
  assert.equal(openMode('overlay'), 'overlay')
  assert.equal(openMode('side_by_side'), 'side_by_side')
  for (const value of ['', 'false', false, null, undefined, 'stacked']) assert.equal(openMode(value), null, String(value))
})

test('bali-bpmn:compare opens, switches the comparison, switches the view and closes', () => {
  const closed = { index: 0, mode: null }
  const open = requestedComparison(closed, { index: 1 }, 3)
  assert.deepEqual(open, { index: 1, mode: 'side_by_side' })
  assert.deepEqual(requestedComparison(open, { index: 2 }, 3), { index: 2, mode: 'side_by_side' })
  assert.deepEqual(requestedComparison(open, { mode: 'overlay' }, 3), { index: 1, mode: 'overlay' })
  assert.deepEqual(requestedComparison({ index: 1, mode: 'overlay' }, { index: 0 }, 3), { index: 0, mode: 'overlay' })
  assert.deepEqual(requestedComparison(open, { mode: true }, 3), { index: 1, mode: 'side_by_side' })
  assert.deepEqual(requestedComparison(open, { mode: null }, 3), { index: 1, mode: null })
  assert.deepEqual(requestedComparison(closed, {}, 3), { index: 0, mode: 'side_by_side' })
})

test('a detail asking for what there is not is dropped', () => {
  const open = { index: 0, mode: 'side_by_side' }
  for (const detail of [{ index: 3 }, { index: -1 }, { index: '1' }, { index: 1.5 }, { mode: 'stacked' }, null, 'overlay']) {
    assert.equal(requestedComparison(open, detail, 3), null, JSON.stringify(detail))
  }
  assert.equal(requestedComparison(open, { index: 0 }, 0), null)
})

test('the overlay is drawn only for versions of one process', () => {
  assert.equal(shownMode('overlay', true), 'overlay')
  assert.equal(shownMode('overlay', false), 'side_by_side')
  assert.equal(shownMode('side_by_side', true), 'side_by_side')
})
