import { Controller } from '@hotwired/stimulus'

// The app's own «Compare» menu (dummy-only, not Bali's), for a
// Bali::BpmnEditor drawn without its top bar (`chrome: :minimal`) and so
// without a «Compare» button. It only uses what the editor offers:
//   - `bali-bpmn:compare` { index, mode } to open, switch or close
//     (`{ mode: null }`) the comparison;
//   - `bali-bpmn:compare-change` { open, index, mode } to keep the menu in
//     step: the person also closes it with «×» or picks another option, or
//     another view, in the comparison's own bar.
// The editor is the one inside this controller's element.
export default class extends Controller {
  static targets = ['option', 'view']

  connect () {
    this.onChange = (event) => { if (event.target === this.editor()) this.show(event.detail || {}) }
    this.element.addEventListener('bali-bpmn:compare-change', this.onChange)
  }

  disconnect () {
    this.element.removeEventListener('bali-bpmn:compare-change', this.onChange)
  }

  editor () {
    return this.element.querySelector('.bali-bpmn-editor')
  }

  // The option picked: '' closes, an index opens or switches.
  pick () {
    const value = this.optionTarget.value
    this.send(value === '' ? { mode: null } : { index: Number(value), mode: this.hasViewTarget ? this.viewTarget.value : undefined })
  }

  // The view picked, while the comparison is open.
  view () {
    if (this.optionTarget.value !== '') this.send({ mode: this.viewTarget.value })
  }

  send (detail) {
    const editor = this.editor()
    if (editor) editor.dispatchEvent(new CustomEvent('bali-bpmn:compare', { detail }))
  }

  show ({ open, index, mode }) {
    this.optionTarget.value = open ? String(index) : ''
    if (!this.hasViewTarget) return
    this.viewTarget.disabled = !open
    if (open) this.viewTarget.value = mode
  }
}
