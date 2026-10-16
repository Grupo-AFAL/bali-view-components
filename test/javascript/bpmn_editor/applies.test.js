import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { CATALOG, rulesFor, ruleCatalog } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../app/components/bali/bpmn_editor/model/rules/afal.js'
import { PALETTE_ITEMS } from '../../../app/components/bali/bpmn_editor/model/catalog.js'

const ALL = [...CATALOG, ...AFAL_RULES]

// Every rule says which elements it inspects, by palette key: the catalog lists
// an element's rules from that, never from a hand-kept list.
for (const rule of ALL) {
  test(`${rule.id} declares the palette keys it applies to`, () => {
    assert.ok(Array.isArray(rule.appliesTo), `${rule.id} has no appliesTo`)
    assert.ok(rule.appliesTo.length > 0, `${rule.id} applies to nothing`)
    const unknown = rule.appliesTo.filter((key) => !(key in PALETTE_ITEMS))
    assert.deepEqual(unknown, [], `${rule.id} names keys the palette does not have`)
  })
}

test('an element lists the rules that apply to it, the optional package\'s marked', () => {
  const yesNo = rulesFor('binary_decision', ALL)
  assert.ok(yesNo.some((r) => r.id === 'COM-02' && !r.optional))
  assert.ok(rulesFor('task', ALL).some((r) => r.id === 'ACT-02' && r.optional))
  assert.deepEqual(rulesFor('task', CATALOG).filter((r) => r.optional), [], 'the built-in catalogue has no optional rule')
})

// The Lookbook catalog preview (Ruby) reads a snapshot of the catalogue; it
// must be the live one.
test('the rule catalogue snapshot is the live catalogue', () => {
  const stored = JSON.parse(fs.readFileSync(new URL('../../fixtures/bpmn_editor/rule_catalog.json', import.meta.url), 'utf8'))
  assert.deepEqual(stored, ruleCatalog(ALL),
    'test/fixtures/bpmn_editor/rule_catalog.json is stale; regenerate it with\n' +
    '  node test/javascript/bpmn_editor/bin/rule_catalog.js > test/fixtures/bpmn_editor/rule_catalog.json')
})
