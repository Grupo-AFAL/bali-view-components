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
    readOnlyNotice: { type: String, default: '' },
    autosave: { type: Boolean, default: true },
    // 'horizontal' | 'vertical' fixes the lanes' orientation; '' lets the user switch.
    orientation: { type: String, default: '' },
    // { items: [{ key, state, note }], note_legend } — Bali::BpmnEditor::Palette.resolve.
    palette: { type: Object, default: {} },
    legend: { type: Array, default: [] },
    rules: { type: Object, default: {} },
    nodeFields: { type: Object, default: {} },
    laneFields: { type: Array, default: [] },
    urls: { type: Object, default: {} },
    name: { type: String, default: '' },
    watermark: { type: String, default: '' },
    // [{ key, label, color }] — the tags review notes can carry.
    annotationTags: { type: Array, default: [] },
    // { document, label } — a version to compare against; {} = none.
    compare: { type: Object, default: {} },
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
