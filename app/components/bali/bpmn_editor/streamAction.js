// Turbo Stream action `bali_bpmn_event`: how a host's drawer form tells the
// editor that it created something (a sub-process reference, a lane
// assignee). Bali::BpmnEditorHelper#bali_bpmn_event renders it:
//
//   <turbo-stream action="bali_bpmn_event" target="flow_1_bpmn"
//                 event="reference-created" detail='{"client_node_id":"n9",…}'>
//
// It dispatches `bali-bpmn:<event>` on the editor element its target names —
// only there: two editors on a page can hold the same ids, so an event
// for no editor in particular would change the wrong one. A missing target is
// said on the console and dropped. Turbo is reached as the window.Turbo
// global, never imported: the island bundle must not carry a second copy.
export const STREAM_ACTION = 'bali_bpmn_event'

export function dispatchStreamEvent (element, root = document) {
  const name = element.getAttribute('event')
  if (!name) return false
  const targetId = element.getAttribute('target')
  const target = targetId ? root.getElementById(targetId) : null
  if (!target) {
    console.warn(`bali_bpmn_event "${name}": no editor with id ${JSON.stringify(targetId)} on the page; the event was dropped.`)
    return false
  }
  let detail = {}
  try {
    detail = JSON.parse(element.getAttribute('detail') || '{}')
  } catch {
    console.warn(`bali_bpmn_event "${name}": its detail is not JSON; the event went out without it.`)
  }
  target.dispatchEvent(new CustomEvent(`bali-bpmn:${name}`, { bubbles: true, detail }))
  return true
}

// Installed when the island's entry loads. A page whose Turbo arrives later
// (a deferred script) gets it on the first turbo:load.
export function installBpmnStreamAction (win = typeof window !== 'undefined' ? window : null) {
  if (!win) return
  const actions = win.Turbo && win.Turbo.StreamActions
  if (!actions) {
    win.addEventListener('turbo:load', () => installBpmnStreamAction(win), { once: true })
    return
  }
  if (actions[STREAM_ACTION]) return
  actions[STREAM_ACTION] = function () { dispatchStreamEvent(this) }
}
