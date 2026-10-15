/**
 * Bali BPMN Editor Island - Optional Module
 *
 * Requires React and React Flow; import it only where the editor is needed,
 * never from the main bundle. Optional peers:
 *
 *   yarn add react react-dom @xyflow/react @rails/request.js
 *
 *   import { registerBpmnEditor, registerBpmnRule } from 'bali-view-components/bpmn-editor'
 *   registerBpmnEditor(application)
 *
 * or make 'bali-view-components/bpmn-editor-entry' a dedicated bundler entry
 * and lazy-load it with 'bali-view-components/bpmn-editor-loader'
 * (docs/api/bpmn-editor.md).
 */
import { BpmnEditorController } from '../../components/bali/bpmn_editor/index'
import { installBpmnStreamAction } from '../../components/bali/bpmn_editor/streamAction'

export { BpmnEditorController } from '../../components/bali/bpmn_editor/index'
export { registerBpmnRule } from '../../components/bali/bpmn_editor/model/rules'

export function registerBpmnEditor (application) {
  application.register('bpmn-editor', BpmnEditorController)
  installBpmnStreamAction()
}
