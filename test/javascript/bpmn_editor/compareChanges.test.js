import { test } from 'node:test'
import assert from 'node:assert/strict'
import { diffDocuments } from '../../../app/components/bali/bpmn_editor/model/diff.js'
import { changeRows } from '../../../app/components/bali/bpmn_editor/model/compareChanges.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import { doc, lanes, node, flow } from './helpers.js'

const t = translator({})
const base = () => doc({
  lanes: lanes('Desk', 'Treasury', 'Legal'),
  nodes: [node('s', 'start_event', 'l1', 100, 90), node('t1', 'task', 'l1', 260, 90, { name: 'Validate' }), node('t2', 'task', 'l2', 460, 270, { name: 'Pay' }), node('t4', 'task', 'l3', 460, 450, { name: 'Sign' })],
  edges: [flow('f1', 's', 't1'), flow('f2', 't1', 't2')]
})

// What a host prints as the table beside the two drawings: one row per
// element of the comparison's list of changes, in its words.
test('the changes as rows: state, mark, kind, type, name, lane and the detail the list shows', () => {
  const current = base()
  current.lanes = current.lanes.filter((l) => l.id !== 'l3')
  current.nodes = current.nodes.filter((n) => n.id !== 't4')
  current.nodes[1] = { ...current.nodes[1], type: 'user_task' }
  current.nodes[2] = { ...current.nodes[2], lane_id: 'l1' }
  current.nodes.push(node('t3', 'task', 'l2', 600, 270, { name: 'Archive' }))
  const diff = diffDocuments(base(), current)

  const rows = changeRows(base(), current, diff, t)

  assert.deepEqual(rows.map(({ state, mark, label, kind, id, type, name, lane, reasons, detail }) => [state, mark, label, kind, id, type, name, lane, reasons, detail]), [
    ['changed', 'changed', 'Changed', 'node', 't1', 'user_task', 'Validate', 'Desk', ['type'], ['type: Task → User task']],
    ['changed', 'moved', 'Moved to another lane', 'node', 't2', 'task', 'Pay', 'Desk', ['lane'], ['lane: Treasury → Desk']],
    ['added', 'added', 'Added', 'node', 't3', 'task', 'Archive', 'Treasury', [], []],
    ['removed', 'removed', 'Removed', 'lane', 'l3', null, 'Legal', null, [], []],
    ['removed', 'removed', 'Removed', 'node', 't4', 'task', 'Sign', 'Legal', [], []]
  ])
})
