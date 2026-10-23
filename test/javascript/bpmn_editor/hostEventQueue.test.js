import { test } from 'node:test'
import assert from 'node:assert/strict'
import { hostEventQueue } from '../../../app/components/bali/bpmn_editor/hostEventQueue.js'

const send = (target, name, detail) => target.dispatchEvent(new CustomEvent(`bali-bpmn:${name}`, { detail }))

test('keeps what the app sent to this editor before the island took it, in order, and nothing after', () => {
  const element = new EventTarget()
  const queue = hostEventQueue(element)
  send(element, 'compare', { index: 1 })
  send(element, 'reload', {})
  send(element, 'select', { node_id: 'n1' })
  send(element, 'compare', { mode: 'overlay' })

  assert.deepEqual(queue.take().map((e) => [e.type, e.detail]), [
    ['bali-bpmn:compare', { index: 1 }], ['bali-bpmn:select', { node_id: 'n1' }], ['bali-bpmn:compare', { mode: 'overlay' }]
  ])
  send(element, 'badges', { visible: false })
  assert.deepEqual(queue.take(), [])
})

test('stops listening on disconnect', () => {
  const element = new EventTarget()
  const queue = hostEventQueue(element)
  queue.stop()
  send(element, 'compare', { index: 1 })
  assert.deepEqual(queue.take(), [])
})
