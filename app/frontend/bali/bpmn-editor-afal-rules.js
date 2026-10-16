/**
 * Bali BPMN Editor - AFAL's modelling guidelines (optional)
 *
 * The rules of AFAL's BPMN criteria matrix that are AFAL guidelines rather
 * than BPMN 2.0 (Criterios BPMN Rev.01, origin «Lineamiento AFAL»): rework
 * through a merging XOR, distinct end names, labelled related-procedure flows,
 * a diagram legible on its page and the wording of activities and lanes.
 * Importing this module registers them; each one can still be turned off with
 * `rules: { disabled: [...] }`.
 *
 * Import it in the SAME bundle as the editor, so both share one rule registry:
 * in the island's own entry (app/javascript/bpmn-editor-island.js)
 *
 *   import 'bali-view-components/bpmn-editor-entry'
 *   import 'bali-view-components/bpmn-editor/afal-rules'
 *
 * or next to registerBpmnEditor(application) when the editor is in the main
 * bundle. Imported from another bundle it registers into a registry the editor
 * never reads.
 */
import { registerBpmnRule } from '../../components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../components/bali/bpmn_editor/model/rules/afal.js'

export const AFAL_RULE_IDS = AFAL_RULES.map((rule) => rule.id)

for (const rule of AFAL_RULES) registerBpmnRule(rule)
