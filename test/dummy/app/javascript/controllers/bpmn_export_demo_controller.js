import { Controller } from '@hotwired/stimulus'

// The app asking Bali::BpmnEditor for its drawing (dummy-only, not Bali's):
// `bali-bpmn:export` { request_id, format, frame } on the editor inside this
// element, and the `bali-bpmn:exported` / `bali-bpmn:export-failed` with that
// request_id shown below it — what a host would post to its server to lay
// the drawing in its own PDF.
export default class extends Controller {
  static targets = ['result']

  connect () {
    this.sequence = 0
    this.onExported = (event) => this.show(event.detail)
    this.onFailed = (event) => { this.resultTarget.textContent = `export-failed ${event.detail.request_id}: ${event.detail.message}` }
    this.element.addEventListener('bali-bpmn:exported', this.onExported)
    this.element.addEventListener('bali-bpmn:export-failed', this.onFailed)
  }

  disconnect () {
    this.element.removeEventListener('bali-bpmn:exported', this.onExported)
    this.element.removeEventListener('bali-bpmn:export-failed', this.onFailed)
  }

  request ({ params: { format, frame } }) {
    this.pending = `${this.element.querySelector('.bali-bpmn-editor').id}-${++this.sequence}`
    this.element.querySelector('.bali-bpmn-editor').dispatchEvent(new CustomEvent('bali-bpmn:export', { detail: { request_id: this.pending, format, frame } }))
  }

  show (detail) {
    if (detail.request_id !== this.pending) return
    const parts = [this.figure(detail, `request_id ${detail.request_id} · ${detail.format} · ${detail.width}×${detail.height}${detail.scale ? ` · scale ${detail.scale}` : ''}`)]
    const comparison = detail.comparison
    if (comparison) {
      parts.push(this.figure(comparison.before, `before · ${comparison.label}`), this.figure(comparison.after, 'after'))
      const json = document.createElement('pre')
      json.className = 'max-h-80 overflow-auto rounded bg-base-200 p-2 text-xs'
      json.dataset.testid = 'bpmn-export-summary'
      json.textContent = JSON.stringify({ summary: comparison.summary, changes: comparison.changes }, null, 2)
      parts.push(json)
    }
    this.resultTarget.replaceChildren(...parts)
  }

  figure (drawing, caption) {
    const figure = document.createElement('figure')
    figure.className = 'flex flex-col gap-1'
    const image = document.createElement('img')
    image.className = 'max-w-full border border-base-300'
    image.alt = caption
    image.src = drawing.png || `data:image/svg+xml;charset=utf-8,${encodeURIComponent(drawing.svg)}`
    const text = document.createElement('figcaption')
    text.className = 'text-xs text-base-content/60'
    text.textContent = caption
    figure.append(image, text)
    return figure
  }
}
