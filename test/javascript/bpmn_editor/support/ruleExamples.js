// The rule examples, kept once in test/fixtures/bpmn_editor/ and read by the
// JS tests (rules.test.js, criteria.test.js) and by the dummy app's rules
// gallery preview (BpmnSampleFlows.rule_example).
//
// rule_examples.json: { documents: { name → document }, rules: { rule id →
//   { package?, failing, passing, options?, allowed?, page?, also?, why? } } }
//   — `package: "optional"` marks a rule of the optional package
//   (bali-view-components/bpmn-editor/afal-rules); a document given as a
//   string names one in `documents`; every text is { en, es }, so the gallery
//   shows each example in the language its word lists check. `also` lists
//   the rules the failing example cannot help breaking too, `why` says why.
//   criteria_examples.json: [{ codes, rules, failing, passing, allowed?,
//   page? }], several examples per rule, in Spanish.
import fs from 'node:fs'
import { translator } from '../../../../app/components/bali/bpmn_editor/i18n.js'

const read = (name) => JSON.parse(fs.readFileSync(new URL(`../../../fixtures/bpmn_editor/${name}`, import.meta.url), 'utf8'))

export const RULE_EXAMPLES = read('rule_examples.json')
export const CRITERIA_EXAMPLES = read('criteria_examples.json')

const localize = (value, locale) => {
  if (Array.isArray(value)) return value.map((v) => localize(v, locale))
  if (value && typeof value === 'object') {
    const keys = Object.keys(value).sort().join()
    if (keys === 'en,es') return value[locale]
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, localize(v, locale)]))
  }
  return value
}

// A fresh copy in `locale`: the tests mutate what they get.
export function exampleDocument (value, locale = 'en') {
  return localize(structuredClone(typeof value === 'string' ? RULE_EXAMPLES.documents[value] : value), locale)
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

// The island table of the Spanish locale file the gem ships, and a
// translator per language: what the word lists of each locale say.
function spanishTable () {
  const lines = fs.readFileSync(new URL('../../../../config/locales/bali_view.es.yml', import.meta.url), 'utf8').split('\n')
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

export const TRANSLATORS = { en: translator({}), es: translator(spanishTable()) }
