// The rule examples, kept once in test/fixtures/bpmn_editor/ and read by the
// JS tests (rules.test.js, criteria.test.js) and by the dummy app's rules
// gallery preview (BpmnSampleFlows.rule_example).
//
// rule_examples.json: { documents: { name → document }, rules: { rule id →
//   { failing, passing, options?, allowed?, page? } } } — a document given as a
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

// What the example needs from the host besides the document: rule options,
// the palette it allows, the sheet it prints on.
export function exampleOptions (entry) {
  return {
    options: entry.options,
    allowed: entry.allowed ? new Set(entry.allowed) : undefined,
    page: entry.page
  }
}
