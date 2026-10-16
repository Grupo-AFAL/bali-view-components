// One wrong and one right use per criterion code a rule checks (several per
// rule): the wrong use must raise the rule, the right one must not. The
// examples are written in Spanish, so the wording rules are checked against the
// word lists the Spanish locale ships (bali_view.es.yml). They live in
// test/fixtures/bpmn_editor/criteria_examples.json.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { evaluate, CATALOG } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../app/components/bali/bpmn_editor/model/rules/afal.js'
// The optional rule package, registered as a host that imports it does.
import '../../../app/frontend/bali/bpmn-editor-afal-rules.js'
import { CRITERIA_EXAMPLES, exampleDocument, TRANSLATORS } from './support/ruleExamples.js'

const t = TRANSLATORS.es
const ALL = { enabled: [...CATALOG.map((r) => r.id)] }

for (const c of CRITERIA_EXAMPLES) {
  test(`${c.codes.join(', ')}: the wrong use raises ${c.rules.join(' or ')}, the right use does not`, () => {
    const allowed = c.allowed ? new Set(c.allowed) : undefined
    const issues = (d) => evaluate(exampleDocument(d), ALL, t, { allowed, page: c.page }).filter((i) => c.rules.includes(i.rule))
    assert.ok(issues(c.failing).length > 0, 'the wrong use is flagged')
    assert.deepEqual(issues(c.passing).map((i) => `${i.rule}: ${i.message}`), [], 'the right use passes')
  })
}

// Each use raises nothing but its own rules: the central rules on as they
// ship, the optional package registered, the example's rules switched on.
// The examples are Spanish, so the Spanish word lists check them.
for (const c of CRITERIA_EXAMPLES) {
  test(`${c.codes.join(', ')}: the wrong use raises only ${c.rules.join(' or ')}, the right use nothing`, () => {
    const allowed = c.allowed ? new Set(c.allowed) : undefined
    const raised = (d) => [...new Set(evaluate(exampleDocument(d), { enabled: c.rules }, t, { allowed, page: c.page }).map((i) => i.rule))].sort()
    const failing = raised(c.failing)
    assert.ok(failing.some((id) => c.rules.includes(id)), 'the wrong use is flagged')
    assert.deepEqual(failing.filter((id) => !c.rules.includes(id) && !(c.also || []).includes(id)), [], 'and nothing else')
    assert.deepEqual(raised(c.passing), [], 'the right use raises nothing')
  })
}

test('every criterion a rule cites has an example here', () => {
  const covered = new Set(CRITERIA_EXAMPLES.flatMap((c) => c.codes))
  const missing = [...new Set([...CATALOG, ...AFAL_RULES].flatMap((rule) => rule.criteria || []))].filter((code) => !covered.has(code))
  assert.deepEqual(missing, [])
})
