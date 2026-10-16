// Prints the rule catalogue the Lookbook catalog preview reads: the built-in
// rules and the optional package's, with what each applies to.
//
//   node test/javascript/bpmn_editor/bin/rule_catalog.js > test/fixtures/bpmn_editor/rule_catalog.json
import { ruleCatalog, CATALOG } from '../../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../../app/components/bali/bpmn_editor/model/rules/afal.js'

process.stdout.write(JSON.stringify(ruleCatalog([...CATALOG, ...AFAL_RULES]), null, 2) + '\n')
