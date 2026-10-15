/**
 * Bali BPMN Editor Island - Self-registering entry
 *
 * The whole body of a dedicated bundler entry (e.g.
 * app/javascript/bpmn-editor-island.js):
 *
 *   import 'bali-view-components/bpmn-editor-entry'
 *
 * Its own entry because the editor imports CSS from JS (@xyflow/react's
 * stylesheet and the island's flow.css), which esbuild emits as the entry's
 * .css file, and because React + React Flow are too heavy for the main
 * bundle. Registers on window.Stimulus, never a second Application.
 */
import { registerIsland } from './react-island'
import { BpmnEditorController } from '../../components/bali/bpmn_editor/index'
import { installBpmnStreamAction } from '../../components/bali/bpmn_editor/streamAction'

registerIsland('bpmn-editor', BpmnEditorController)
installBpmnStreamAction()
