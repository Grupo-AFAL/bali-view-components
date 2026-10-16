// One wrong and one right use per criterion code a rule checks (several per
// rule): the wrong use must raise the rule, the right one must not. The
// examples are written in Spanish, so the wording rules are checked against the
// word lists the Spanish locale ships (bali_view.es.yml). They live in
// test/fixtures/bpmn_editor/criteria_examples.json.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { evaluate, CATALOG } from '../../../app/components/bali/bpmn_editor/model/rules/engine.js'
import { AFAL_RULES } from '../../../app/components/bali/bpmn_editor/model/rules/afal.js'
// The optional rule package, registered as a host that imports it does.
import '../../../app/frontend/bali/bpmn-editor-afal-rules.js'
import { translator } from '../../../app/components/bali/bpmn_editor/i18n.js'
import { CRITERIA_EXAMPLES, exampleDocument } from './support/ruleExamples.js'

// The Spanish island table, read from the locale file the gem ships.
function spanish () {
  const lines = fs.readFileSync(new URL('../../../config/locales/bali_view.es.yml', import.meta.url), 'utf8').split('\n')
  const start = lines.indexOf('    bpmn_editor:')
  const table = {}
  let inside = false
  for (const line of lines.slice(start + 1)) {
    if (line === '      island:') { inside = true; continue }
    if (!inside) continue
    const match = line.match(/^ {8}([\w-]+): (".*")$/)
    if (!match) { if (!/^ {8}/.test(line) && line.trim()) break; continue }
    table[match[1]] = JSON.parse(match[2])
  }
  return table
}
const t = translator(spanish())
const ALL = { enabled: [...CATALOG.map((r) => r.id)] }

for (const c of CRITERIA_EXAMPLES) {
  test(`${c.codes.join(', ')}: the wrong use raises ${c.rules.join(' or ')}, the right use does not`, () => {
    const allowed = c.allowed ? new Set(c.allowed) : undefined
    const issues = (d) => evaluate(exampleDocument(d), ALL, t, { allowed, page: c.page }).filter((i) => c.rules.includes(i.rule))
    assert.ok(issues(c.failing).length > 0, 'the wrong use is flagged')
    assert.deepEqual(issues(c.passing).map((i) => `${i.rule}: ${i.message}`), [], 'the right use passes')
  })
}

test('every criterion a rule cites has an example here', () => {
  const covered = new Set(CRITERIA_EXAMPLES.flatMap((c) => c.codes))
  const missing = [...new Set([...CATALOG, ...AFAL_RULES].flatMap((rule) => rule.criteria || []))].filter((code) => !covered.has(code))
  assert.deepEqual(missing, [])
})
