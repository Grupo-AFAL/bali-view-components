// Every palette element is described three ways, in both languages the gem
// ships: what it is (summary), when to use it (when) and what this editor
// does with it (editor). The palette's tooltip and the catalog preview read
// these; the rules that apply to an element come from the rules catalog, so
// an `editor` text never names a rule.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import { PALETTE_ITEMS } from '../../../app/components/bali/bpmn_editor/model/catalog.js'
import { DEFAULT_I18N } from '../../../app/components/bali/bpmn_editor/i18n.js'

// The Spanish island table, read from the locale file the gem ships.
function spanish () {
  const lines = fs.readFileSync(new URL('../../../config/locales/bali_view.es.yml', import.meta.url), 'utf8').split('\n')
  const table = {}
  let inside = false
  for (const line of lines.slice(lines.indexOf('    bpmn_editor:') + 1)) {
    if (line === '      island:') { inside = true; continue }
    if (!inside) continue
    const match = line.match(/^ {8}([\w-]+): (".*")$/)
    if (!match) { if (!/^ {8}/.test(line) && line.trim()) break; continue }
    table[match[1]] = JSON.parse(match[2])
  }
  return table
}

const TABLES = { en: DEFAULT_I18N, es: spanish() }
const PARTS = ['summary', 'when', 'editor']
const placeholders = (text) => (String(text).match(/%\{\w+\}/g) || []).sort()

for (const key of Object.keys(PALETTE_ITEMS)) {
  test(`${key} has its summary, when and editor texts in English and Spanish`, () => {
    for (const part of PARTS) {
      const id = `palette_${key}_${part}`
      for (const [locale, table] of Object.entries(TABLES)) {
        assert.ok(typeof table[id] === 'string' && table[id].trim().length > 10, `${locale}: ${id}`)
      }
      assert.deepEqual(placeholders(TABLES.es[id]), placeholders(TABLES.en[id]), `placeholders of ${id}`)
    }
    for (const [locale, table] of Object.entries(TABLES)) {
      assert.doesNotMatch(table[`palette_${key}_editor`], /\b(?:R\d{2}|B\d{2}|[A-Z]{3}-\d{2})\b/, `${locale}: the rules come from the catalog, not the text`)
    }
  })
}
