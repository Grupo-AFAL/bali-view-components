// Stimulus controller of the BPMN editor island (#1489). Values map 1:1 to
// BpmnEditor props through the ReactIslandController base; react, react-dom
// and @xyflow/react are imported here so the bundler attributes them to the
// island's entry and the main bundle stays React-free.
import { ReactIslandController } from '../../../frontend/bali/react-island'

// The `rules` the island takes: false (Component `rules: false`, its own
// value), a profile's name (`rules: :structure` arrives as { profile }), or
// the configuration as is.
export function rulesProp (validate, rules) {
  if (validate === false) return false
  if (rules && rules.profile) return String(rules.profile)
  return rules
}

export class BpmnEditorController extends ReactIslandController {
  static values = {
    // The document — contract in Bali::BpmnEditor::Data.
    data: Object,
    editable: { type: Boolean, default: false },
    autosave: { type: Boolean, default: true },
    // Keeps the document's own orientation: no switch in the toolbar.
    lockOrientation: { type: Boolean, default: false },
    // Lanes may be marked as external participants (the lane panel's checkbox).
    externalLanes: { type: Boolean, default: true },
    // Opens the pending-issues panel on load (Component `open_issues:`).
    openIssues: { type: Boolean, default: false },
    // 'compact' | 'straight' — autoLayout's mode (model/layout.js).
    layout: { type: String, default: 'compact' },
    // { width, height } in inches and orientation — model/page.js.
    page: { type: Object, default: {} },
    // { items: [{ key, state, note }], note_legend } — Bali::BpmnEditor::Palette.resolve.
    palette: { type: Object, default: {} },
    legend: { type: Array, default: [] },
    rules: { type: Object, default: {} },
    // false: Component `rules: false` — a Stimulus Object value reads only objects, so
    // the `false` arrives on its own and componentProps hands BpmnEditor `rules: false`.
    validate: { type: Boolean, default: true },
    // { nodes: { type or '*' => [field] }, lanes: [field] } — the properties panel's own fields.
    fields: { type: Object, default: {} },
    urls: { type: Object, default: {} },
    name: { type: String, default: '' },
    watermark: { type: String, default: '' },
    // { tags: [{ key, label, color }], compare_with: { document, label } } — review notes and comparison.
    review: { type: Object, default: {} },
    i18n: { type: Object, default: {} },
    // The node selected on load, read-only too (Component `selected_id:`).
    selectedId: { type: String, default: '' },
    // 'full' | 'minimal' (Component `chrome:`).
    chrome: { type: String, default: 'full' },
    // The floor of "Fit to view" (Component `min_zoom:`, canvas/fit.js).
    minZoom: { type: Number, default: 0.4 },
    // Review notes on a read-only diagram, saved to urls.annotations.
    annotatable: { type: Boolean, default: false }
  }

  mountElement () {
    return this.element.querySelector('.bali-bpmn-editor-mount') || this.element
  }

  componentProps () {
    const { validate, ...props } = super.componentProps()
    return { ...props, rules: rulesProp(validate, props.rules), hostElement: this.element }
  }

  async loadComponent () {
    const [react, reactDom, { default: BpmnEditor }] = await Promise.all([
      import('react'),
      import('react-dom/client'),
      import('./BpmnEditor.jsx')
    ])

    return { react, reactDom, Component: BpmnEditor }
  }

  errorFallback () {
    return this.i18nValue.load_error || 'The diagram failed to load.'
  }
}
