import { test } from 'node:test'
import assert from 'node:assert/strict'
import { exportRequest, answerExport } from '../../../app/components/bali/bpmn_editor/model/exportRequest.js'
import { hostEventHandlers } from '../../../app/components/bali/bpmn_editor/model/hostEvents.js'
import { hostEventQueue } from '../../../app/components/bali/bpmn_editor/hostEventQueue.js'

test('an export request defaults to a framed SVG and keeps the app\'s request_id as sent', () => {
  assert.deepEqual(exportRequest({ request_id: 'a1' }), { requestId: 'a1', format: 'svg', frame: true, fontFamily: null })
  assert.deepEqual(exportRequest({ request_id: 7, format: 'png', frame: false, font_family: ' Inter, sans-serif ' }), { requestId: 7, format: 'png', frame: false, fontFamily: 'Inter, sans-serif' })
  assert.deepEqual(exportRequest(null), { requestId: null, format: 'svg', frame: true, fontFamily: null })
})

test('a request for what there is not is an error naming it, with its request_id', () => {
  for (const [detail, words] of [[{ format: 'pdf' }, /format "pdf"/], [{ frame: 'no' }, /frame must be/], [{ font_family: '' }, /font_family/], [{ font_family: 3 }, /font_family/]]) {
    const request = exportRequest({ request_id: 'x', ...detail })
    assert.equal(request.requestId, 'x')
    assert.match(request.error, words)
  }
})

test('the answer is exported with the request_id, or export-failed with the message', async () => {
  const said = []
  const emit = (name, detail) => said.push([name, detail])

  await answerExport({ request_id: 'ok', frame: false }, async (request) => ({ format: request.format, frame: request.frame, svg: '<svg/>' }), emit)
  await answerExport({ request_id: 'bad', format: 'gif' }, () => assert.fail('an invalid request is not drawn'), emit)
  await answerExport({ request_id: 'boom' }, async () => { throw new Error('no canvas') }, emit)

  assert.deepEqual(said, [
    ['exported', { request_id: 'ok', format: 'svg', frame: false, svg: '<svg/>' }],
    ['export-failed', { request_id: 'bad', message: 'unknown export format "gif"; expected one of svg, png' }],
    ['export-failed', { request_id: 'boom', message: 'no canvas' }]
  ])
})

test('bali-bpmn:export reaches the editor, and is kept when sent before the island listens', () => {
  const asked = []
  const handlers = hostEventHandlers({ onExport: (detail) => asked.push(detail) })
  const element = new EventTarget()
  const queue = hostEventQueue(element)
  element.dispatchEvent(new CustomEvent('bali-bpmn:export', { detail: { request_id: 1 } }))

  for (const event of queue.take()) handlers[event.type](event)

  assert.deepEqual(asked, [{ request_id: 1 }])
})
