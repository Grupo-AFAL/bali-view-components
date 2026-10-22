import { test } from 'node:test'
import assert from 'node:assert/strict'
import { hostEventHandlers, replayThenReady } from '../../../app/components/bali/bpmn_editor/model/hostEvents.js'
import { hostEventQueue } from '../../../app/components/bali/bpmn_editor/hostEventQueue.js'

const send = (target, name, detail) => target.dispatchEvent(new CustomEvent(`bali-bpmn:${name}`, { detail }))

// The editor around the handlers: a document the operations run against.
function editor (doc) {
  const docRef = { current: doc }
  const selected = []
  const handlers = hostEventHandlers({
    reload: () => {},
    apply: (operation) => { const result = operation(docRef.current); if (!result.error) docRef.current = result.doc; return result },
    docRef,
    onSelect: (id) => selected.push(id)
  })
  return { docRef, selected, handlers }
}

const lanes = (...list) => ({ lanes: list, nodes: [], edges: [], annotations: [] })

// An app that answers `ready` with a select: that select is the last word, not
// the one it sent before the island listened.
test('the queued events are applied before ready, so what the app sends on ready wins', async () => {
  const element = new EventTarget()
  const queue = hostEventQueue(element)
  send(element, 'select', { node_id: 'A' })
  const { selected, handlers } = editor(lanes())
  element.addEventListener('bali-bpmn:select', (event) => handlers[event.type](event))
  element.addEventListener('bali-bpmn:ready', () => send(element, 'select', { node_id: 'B' }))

  replayThenReady(queue.take(), (event) => handlers[event.type](event), () => send(element, 'ready', {}))
  await Promise.resolve()

  assert.deepEqual(selected, ['A', 'B'])
})

test('a lane assignee created in the drawer keeps the name the person gave the lane, as picking it in the search does', () => {
  const { docRef, handlers } = editor(lanes({ id: 'l1', name: 'Accounts payable' }, { id: 'l2', name: '' }))
  const created = (laneId, label) => handlers['bali-bpmn:lane-assignee-created']({ detail: { client_lane_id: laneId, assignee: { id: '9', label } } })

  created('l1', 'Finance team')
  created('l2', 'Treasury')

  assert.deepEqual(docRef.current.lanes.map((l) => [l.name, l.assignee.label]), [['Accounts payable', 'Finance team'], ['Treasury', 'Treasury']])
})
