import { Controller } from '@hotwired/stimulus'

// The Lookbook "Host integration" preview's own controller (not Bali's): a
// live list of the `bali-bpmn:*` events the editors inside it send, and the
// unsaved-changes mark on the tab that holds an editor, from
// `bali-bpmn:dirty-change`.
const EVENTS = ['dirty-change', 'saved', 'finalized', 'open-reference']

// A saved document is long: the console shows its version and size.
function summary (detail) {
  if (!detail || !detail.document) return JSON.stringify(detail)
  const { document, ...rest } = detail
  return JSON.stringify({ ...rest, document: { version: document.version, nodes: (document.nodes || []).length, issues: (document.issues || []).length } })
}

export default class extends Controller {
  static targets = ['log', 'empty']

  connect () {
    this.listener = (event) => this.record(event)
    for (const name of EVENTS) this.element.addEventListener(`bali-bpmn:${name}`, this.listener)
  }

  disconnect () {
    for (const name of EVENTS) this.element.removeEventListener(`bali-bpmn:${name}`, this.listener)
  }

  record (event) {
    const name = event.type.replace('bali-bpmn:', '')
    const row = document.createElement('li')
    row.className = 'font-mono text-xs'
    row.dataset.event = name
    row.textContent = `${new Date().toLocaleTimeString()}  #${event.target.id}  ${name}  ${summary(event.detail)}`
    this.logTarget.prepend(row)
    if (this.hasEmptyTarget) this.emptyTarget.hidden = true
    if (name === 'dirty-change') this.markTab(event.target, event.detail && event.detail.dirty)
  }

  // Bali::Tabs labels the panel with its tab's id.
  markTab (editor, dirty) {
    const panel = editor.closest('[role="tabpanel"]')
    const tab = panel && document.getElementById(panel.getAttribute('aria-labelledby'))
    if (!tab) return
    let dot = tab.querySelector('[data-unsaved]')
    if (!dot) {
      dot = document.createElement('span')
      dot.dataset.unsaved = ''
      dot.className = 'ml-1 inline-block h-2 w-2 rounded-full bg-warning'
      dot.setAttribute('aria-label', 'unsaved changes')
      tab.append(dot)
    }
    dot.hidden = !dirty
  }

  clear () {
    this.logTarget.replaceChildren()
    if (this.hasEmptyTarget) this.emptyTarget.hidden = false
  }
}
