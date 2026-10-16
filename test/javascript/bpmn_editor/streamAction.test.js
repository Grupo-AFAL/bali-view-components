import { test, mock } from 'node:test'
import assert from 'node:assert/strict'
import { dispatchStreamEvent, installBpmnStreamAction, STREAM_ACTION } from '../../../app/components/bali/bpmn_editor/streamAction.js'

// The <turbo-stream> element and the page, as far as the action reads them.
const streamElement = (attrs) => ({ getAttribute: (name) => (name in attrs ? attrs[name] : null) })
function page (ids) {
  const elements = Object.fromEntries(ids.map((id) => [id, new EventTarget()]))
  return { elements, getElementById: (id) => elements[id] || null }
}

test('the event goes to the editor its target names, with its detail', () => {
  const root = page(['flow_bpmn', 'other_bpmn'])
  const got = []
  root.elements.flow_bpmn.addEventListener('bali-bpmn:reference-created', (e) => got.push(['flow', e.detail]))
  root.elements.other_bpmn.addEventListener('bali-bpmn:reference-created', () => got.push(['other']))
  const sent = dispatchStreamEvent(streamElement({ event: 'reference-created', target: 'flow_bpmn', detail: '{"client_node_id":"n9"}' }), root)
  assert.equal(sent, true)
  assert.deepEqual(got, [['flow', { client_node_id: 'n9' }]])
})

test('a target that is not on the page, or no target at all, drops the event and says so', () => {
  const root = page(['flow_bpmn'])
  const warn = mock.method(console, 'warn', () => {})
  let reached = 0
  root.elements.flow_bpmn.addEventListener('bali-bpmn:reload', () => reached++)
  assert.equal(dispatchStreamEvent(streamElement({ event: 'reload', target: 'gone_bpmn' }), root), false)
  assert.equal(dispatchStreamEvent(streamElement({ event: 'reload' }), root), false)
  assert.equal(reached, 0)
  assert.equal(warn.mock.callCount(), 2)
  assert.match(warn.mock.calls[0].arguments[0], /gone_bpmn/)
  warn.mock.restore()
})

test('a detail that is not JSON still delivers the event, without it, and says so', () => {
  const root = page(['flow_bpmn'])
  const warn = mock.method(console, 'warn', () => {})
  let detail = null
  root.elements.flow_bpmn.addEventListener('bali-bpmn:reload', (e) => { detail = e.detail })
  assert.equal(dispatchStreamEvent(streamElement({ event: 'reload', target: 'flow_bpmn', detail: '{nope' }), root), true)
  assert.deepEqual(detail, {})
  assert.equal(warn.mock.callCount(), 1)
  warn.mock.restore()
})

test('installed on Turbo when it is there, or on the first turbo:load when it arrives later', () => {
  const win = new EventTarget()
  installBpmnStreamAction(win)
  win.Turbo = { StreamActions: {} }
  assert.equal(win.Turbo.StreamActions[STREAM_ACTION], undefined)
  win.dispatchEvent(new Event('turbo:load'))
  assert.equal(typeof win.Turbo.StreamActions[STREAM_ACTION], 'function')
})
