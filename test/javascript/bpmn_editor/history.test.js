import { test } from 'node:test'
import assert from 'node:assert/strict'
import * as h from '../../../app/components/bali/bpmn_editor/model/history.js'

test('undo and redo walk the stack of documents', () => {
  let s = h.initialHistory({ n: 0 })
  s = h.commit(s, { n: 1 })
  s = h.commit(s, { n: 2 })
  s = h.undo(s)
  assert.deepEqual(s.present, { n: 1 })
  s = h.redo(s)
  assert.deepEqual(s.present, { n: 2 })
  s = h.undo(h.undo(s))
  assert.deepEqual(s.present, { n: 0 })
  assert.equal(h.undo(s), s, 'nothing left to undo')
})

test('a new commit drops the redo stack', () => {
  let s = h.commit(h.commit(h.initialHistory({ n: 0 }), { n: 1 }), { n: 2 })
  s = h.commit(h.undo(s), { n: 3 })
  assert.equal(s.future.length, 0)
})

test('commits sharing a coalesce key are one undo step', () => {
  let s = h.initialHistory({ name: '' })
  for (const name of ['V', 'Va', 'Val']) s = h.commit(s, { name }, { coalesce: 'name:n1' })
  assert.equal(s.past.length, 1)
  assert.deepEqual(h.undo(s).present, { name: '' })
})

test('every local change bumps the revision; adopting the server answer does not', () => {
  let s = h.commit(h.initialHistory({ n: 0 }), { n: 1 })
  assert.equal(s.revision, 1)
  s = h.adopt(s, { n: 1, version: 7 })
  assert.equal(s.revision, 1)
  assert.equal(s.past.length, 1)
  s = h.undo(s)
  assert.equal(s.revision, 2)
})

test('reset starts a fresh history', () => {
  const s = h.reset(h.commit(h.initialHistory({ n: 0 }), { n: 1 }), { n: 9 })
  assert.deepEqual([s.past.length, s.future.length, s.present.n], [0, 0, 9])
})

test('the history keeps at most HISTORY_LIMIT steps', () => {
  let s = h.initialHistory({ n: 0 })
  for (let i = 1; i <= h.HISTORY_LIMIT + 20; i++) s = h.commit(s, { n: i })
  assert.equal(s.past.length, h.HISTORY_LIMIT)
})

test('a linked related procedure arrives named after its reference (AFAL SUB-02)', async () => {
  const { normalize } = await import('../../../app/components/bali/bpmn_editor/model/document.js')
  const doc = normalize({ lanes: [], edges: [], nodes: [{ id: 's', type: 'sub_process', name: 'Typed by hand', x: 0, y: 0, reference: { id: '7', label: 'Supplier onboarding' } }, { id: 'u', type: 'sub_process', name: 'Unlinked', x: 300, y: 0 }] })
  assert.equal(doc.nodes[0].name, 'Supplier onboarding')
  assert.equal(doc.nodes[1].name, 'Unlinked')
})
