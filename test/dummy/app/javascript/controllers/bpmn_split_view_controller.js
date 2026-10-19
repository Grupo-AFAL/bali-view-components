import { Controller } from '@hotwired/stimulus'

// The Lookbook «Split view» preview's own controller (not Bali's): the app
// side of a map of processes and the flow behind the selected box, inside a
// collapsible `Bali::SplitView`. The detail is fetched, as in an app: a pick
// points the SplitView's Turbo Frame at the dummy's /bpmn_flows/:box, which
// opens the pane with its loading state until the response lands. It only
// uses what the components offer:
//   - `bali-bpmn:selection-change` { node_id } from the map;
//   - `bali-bpmn:open-reference`, taken over (preventDefault) so a click on a
//     box selects it instead of following its link;
//   - `bali-bpmn:select` { node_id } sent to the map, from «Previous» / «Next»
//     and, with null, when the detail closes;
//   - the SplitView opens on its frame's fetch and says `split-view:close`
//     when the person closes it.
export default class extends Controller {
  static targets = ['split', 'map']
  // `url`: the detail's URL with BOX where the box id goes.
  static values = { boxes: Array, url: String }

  connect () {
    this.map = this.mapTarget.querySelector('.bali-bpmn-editor')
    this.frame = this.splitTarget.querySelector('[data-split-view-collapse-target="frame"]')
    this.onSelection = (event) => {
      if (event.target === this.map) this.pick((event.detail || {}).node_id)
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
  pick (boxId, version) {
    const box = this.boxesValue.find((b) => b.id === boxId)
    if (!box) return
    this.box = box
    const url = new URL(this.urlValue.replace('BOX', encodeURIComponent(box.id)), window.location.href)
    if (version) url.searchParams.set('version', version)
    this.frame.src = url.pathname + url.search
  }

  pickVersion (event) {
    if (this.box) this.pick(this.box.id, event.target.value)
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
}
