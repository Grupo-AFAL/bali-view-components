// The rule examples, kept once in test/fixtures/bpmn_editor/ and read by the
// JS tests (rules.test.js, criteria.test.js) and by the dummy app's rules
// gallery preview (BpmnSampleFlows.rule_example).
//
// rule_examples.json: { documents: { name → document }, rules: { rule id →
//   { package?, failing, passing, options?, allowed?, page? } } } — `package:
//   "optional"` marks a rule of the optional package
//   (bali-view-components/bpmn-editor/afal-rules); a document given as a
//   string names one in `documents`. criteria_examples.json: [{ codes, rules,
//   failing, passing, allowed?, page? }], several examples per rule.
import fs from 'node:fs'

const read = (name) => JSON.parse(fs.readFileSync(new URL(`../../../fixtures/bpmn_editor/${name}`, import.meta.url), 'utf8'))

export const RULE_EXAMPLES = read('rule_examples.json')
export const CRITERIA_EXAMPLES = read('criteria_examples.json')

// A fresh copy: the tests mutate what they get.
export function exampleDocument (value) {
  return structuredClone(typeof value === 'string' ? RULE_EXAMPLES.documents[value] : value)
}

// What the failing example needs from the host besides its document — rule
// options, the palette it allows, the sheet it prints on (R19, R20, VIS-10 and
// VIS-02 break on the clean flow under them). The passing example runs with
// the defaults.
export function exampleOptions (entry, which = 'failing') {
  if (which !== 'failing') return {}
  return {
    options: entry.options,
    allowed: entry.allowed ? new Set(entry.allowed) : undefined,
    page: entry.page
  }
}
