// Stimulus controller of the BPMN editor island (#1489). Values map 1:1 to
// BpmnEditor props through the ReactIslandController base; react, react-dom
// and @xyflow/react are imported here so the bundler attributes them to the
// island's entry and the main bundle stays React-free.
import { ReactIslandController } from '../../../frontend/bali/react-island'

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
    // { nodes: { type or '*' => [field] }, lanes: [field] } — the properties panel's own fields.
    fields: { type: Object, default: {} },
    urls: { type: Object, default: {} },
    name: { type: String, default: '' },
    watermark: { type: String, default: '' },
    // { tags: [{ key, label, color }], compare_with: { document, label } } — review notes and comparison.
    review: { type: Object, default: {} },
    i18n: { type: Object, default: {} }
  }

  mountElement () {
    return this.element.querySelector('.bali-bpmn-editor-mount') || this.element
  }

  componentProps () {
    return { ...super.componentProps(), hostElement: this.element }
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
