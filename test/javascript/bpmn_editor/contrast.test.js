import { test } from 'node:test'
import assert from 'node:assert/strict'
import { textOn, contrast, parseHex } from '../../../app/components/bali/bpmn_editor/model/contrast.js'

// The tag colours the previews and the guide use, light and dark, and the
// text each gets must read at WCAG AA (4.5:1) — in any theme, since the
// colour is the host's, not the theme's.
for (const color of ['#2563eb', '#16a34a', '#facc15', '#f97316', '#0f172a', '#e5e7eb', '#fff', '#000000']) {
  test(`a note number on ${color} reads at 4.5:1 or more`, () => {
    const text = textOn(color)
    assert.ok(contrast(parseHex(color), parseHex(text)) >= 4.5, `${text} on ${color}: ${contrast(parseHex(color), parseHex(text)).toFixed(2)}`)
  })
}

test('a colour that is not hex leaves the stylesheet fallback', () => {
  assert.equal(textOn('var(--color-primary)'), null)
  assert.equal(textOn(undefined), null)
})
