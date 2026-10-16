import { test } from 'node:test'
import assert from 'node:assert/strict'
import { diffDocuments, overlayDocument } from '../../../app/components/bali/bpmn_editor/model/diff.js'
import { doc, lanes, node, flow } from './helpers.js'

const base = () => doc({
  lanes: lanes('A', 'B'),
  nodes: [node('s', 'start_event', 'l1', 100, 90), node('t1', 'task', 'l1', 260, 90, { name: 'Validate' }), node('t2', 'task', 'l2', 460, 270, { name: 'Pay' })],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 't2')]
})

test('added, removed and changed by id; a move alone is not a change', () => {
  const current = base()
  current.nodes = current.nodes.filter((n) => n.id !== 't2')
  current.nodes.push(node('t3', 'task', 'l2', 600, 270, { name: 'Archive' }))
  current.nodes[1] = { ...current.nodes[1], name: 'Validate invoice' }
  current.nodes[0] = { ...current.nodes[0], x: current.nodes[0].x + 40 }
  current.edges = [flow('f1', 's', 't1', { label: 'go' })]
  const diff = diffDocuments(base(), current)
  assert.deepEqual(diff.nodes, { t1: 'changed', t3: 'added', t2: 'removed' })
  assert.deepEqual(diff.edges, { f1: 'changed', f2: 'removed' })
  assert.deepEqual(diff.summary, { added: 1, removed: 2, changed: 2 })
})

test('the overlay keeps what was removed so it can be drawn', () => {
  const current = base()
  current.nodes = current.nodes.filter((n) => n.id !== 't2')
  current.edges = current.edges.filter((e) => e.id !== 'f2')
  const overlay = overlayDocument(base(), current)
  assert.ok(overlay.nodes.some((n) => n.id === 't2'))
  assert.ok(overlay.edges.some((e) => e.id === 'f2'))
})
