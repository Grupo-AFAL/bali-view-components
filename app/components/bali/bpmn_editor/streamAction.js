// Turbo Stream action `bali_bpmn_event`: how a host's drawer form tells the
// editor that it created something (a sub-process reference, a lane
// assignee). Bali::BpmnEditor::StreamHelper#bali_bpmn_event renders it:
//
//   <turbo-stream action="bali_bpmn_event" target="flow_1_bpmn"
//                 event="reference-created" detail='{"client_node_id":"n9",…}'>
//
// It dispatches `bali-bpmn:<event>` on the editor element (or on document
// without a target). Turbo is reached as the window.Turbo global, never
// imported: the island bundle must not carry a second copy of it.
export const STREAM_ACTION = 'bali_bpmn_event'

export function dispatchStreamEvent (element) {
  const name = element.getAttribute('event')
  if (!name) return
  let detail = {}
  try {
    detail = JSON.parse(element.getAttribute('detail') || '{}')
  } catch {
    detail = {}
  }
  const targetId = element.getAttribute('target')
  const target = (targetId && document.getElementById(targetId)) || document
  target.dispatchEvent(new CustomEvent(`bali-bpmn:${name}`, { bubbles: true, detail }))
}

export function installBpmnStreamAction () {
  const actions = typeof window !== 'undefined' && window.Turbo && window.Turbo.StreamActions
  if (!actions || actions[STREAM_ACTION]) return
  actions[STREAM_ACTION] = function () { dispatchStreamEvent(this) }
}
