import { test } from 'node:test'
import assert from 'node:assert/strict'
import { large, samples, localized } from './fixtures.js'

// The previews draw samples.json; the 60-activity flow there must be the one
// the generator makes, or the tests and the previews would measure two flows.
test('the stored large sample is the generated one', () => {
  assert.deepEqual(samples().large, large(60, 6, { localized: true }))
})

test('every sample text has both languages', () => {
  for (const [name, doc] of Object.entries(samples())) {
    for (const locale of ['en', 'es']) {
      const d = localized(doc, locale)
      for (const text of [...d.lanes.map((l) => l.name), ...d.nodes.map((n) => n.name), ...d.edges.map((e) => e.label)]) {
        assert.ok(text === undefined || typeof text === 'string', `${name} (${locale}): ${JSON.stringify(text)}`)
      }
    }
  }
})
