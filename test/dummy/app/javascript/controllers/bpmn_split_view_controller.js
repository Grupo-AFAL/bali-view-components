import { Controller } from '@hotwired/stimulus'

// The Lookbook «Split view» preview's own controller (not Bali's): the app
// side of a map of processes and the flow behind the selected box, inside a
// collapsible `Bali::SplitView`. A host writes the same thing with its own
// data — a Turbo Frame the box's link targets instead of the <template>s here
// does as well, and opens the detail the same way. It only uses what the
// components offer:
//   - `bali-bpmn:selection-change` { node_id, reference } from the map;
//   - `bali-bpmn:open-reference`, taken over (preventDefault) so a click on a
//     box selects it instead of following its link;
//   - `bali-bpmn:select` { node_id } sent to the map, from «Previous» / «Next»
//     and, with null, when the detail closes;
//   - the SplitView opens when its frame gets content and says
//     `split-view:close` when the person closes it.
export default class extends Controller {
  static targets = ['split', 'map', 'header', 'flow', 'template', 'empty', 'title', 'version', 'lane']
  static values = { boxes: Array }

  connect () {
    this.map = this.mapTarget.querySelector('.bali-bpmn-editor')
    this.frame = this.splitTarget.querySelector('[data-split-view-collapse-target="frame"]')
    this.onSelection = (event) => {
      if (event.target !== this.map) return
      const detail = event.detail || {}
      this.pick(detail.node_id, detail.lane_name)
    }
    this.onOpenReference = (event) => { if (event.target === this.map) event.preventDefault() }
    // Closed, the box the detail showed is no longer «the one open»: the map
    // drops its selection too, so a click on that same box opens it again.
    this.onClose = () => {
      this.box = null
      this.map.dispatchEvent(new CustomEvent('bali-bpmn:select', { detail: { node_id: null } }))
    }
    this.map.addEventListener('bali-bpmn:selection-change', this.onSelection)
    this.map.addEventListener('bali-bpmn:open-reference', this.onOpenReference)
    this.splitTarget.addEventListener('split-view:close', this.onClose)
    // A deep link: the box the server selected opens its flow.
    this.pick(this.map.dataset.bpmnEditorSelectedIdValue)
  }

  disconnect () {
    this.map.removeEventListener('bali-bpmn:selection-change', this.onSelection)
    this.map.removeEventListener('bali-bpmn:open-reference', this.onOpenReference)
    this.splitTarget.removeEventListener('split-view:close', this.onClose)
  }

  // A box picked on the map (null: the person cleared the selection — the
  // flow on the right stays, as an app may well decide).
  // `lane`: the lane the map put the box in — `selection-change` says so, and
  // the boxes list knows it for the picks the app makes itself.
  pick (boxId, lane) {
    const box = this.boxesValue.find((b) => b.id === boxId)
    if (!box) return
    // Closed (or still sliding out, about to be emptied): a fresh detail,
    // which is what opens the pane again.
    if (this.splitTarget.dataset.splitState !== 'open') this.frame.replaceChildren(this.headerTarget.content.cloneNode(true))
    this.box = box
    this.titleTarget.textContent = box.name
    this.laneTarget.textContent = lane || box.lane || ''
    const versions = this.templateTargets.filter((t) => t.dataset.flow === box.flow)
    this.versionTarget.replaceChildren(...versions.map((t) => new window.Option(t.dataset.label, t.dataset.version)))
    this.versionTarget.disabled = versions.length < 2
    this.show(versions[0] || null)
  }

  pickVersion () {
    this.show(this.templateTargets.find((t) => t.dataset.flow === this.box.flow && t.dataset.version === this.versionTarget.value))
  }

  previous () { this.step(-1) }
  next () { this.step(1) }

  step (delta) {
    const boxes = this.boxesValue
    const index = boxes.findIndex((b) => b.id === (this.box && this.box.id))
    const box = boxes[(index + delta + boxes.length) % boxes.length]
    this.map.dispatchEvent(new CustomEvent('bali-bpmn:select', { detail: { node_id: box.id } }))
    this.pick(box.id)
  }

  // A new editor for the chosen document; the one it replaces disconnects.
  show (template) {
    this.flowTarget.replaceChildren((template || this.emptyTarget).content.cloneNode(true))
  }
}
