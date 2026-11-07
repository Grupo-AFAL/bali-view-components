import { test } from 'node:test'
import assert from 'node:assert/strict'
import { namedExport } from '../../app/assets/javascripts/bali/utils/common-js.js'

// The two namespaces esbuild gave `import('flatpickr/dist/l10n/es.js')`, measured: unsplit the
// names are copied onto it next to the module's own `default`; split it holds only `default`,
// which is `module.exports`.
const Spanish = { rangeSeparator: ' a ' }
const UNSPLIT = { Spanish, default: { es: Spanish } }
const SPLIT = { default: { Spanish, default: { es: Spanish } } }

test('reads a named export from an unsplit namespace', () => {
  assert.equal(namedExport(UNSPLIT, 'Spanish'), Spanish)
})

test('reads it from a split namespace, through default', () => {
  assert.equal(namedExport(SPLIT, 'Spanish'), Spanish)
})

test('is undefined for a missing module or name, without throwing', () => {
  assert.equal(namedExport(undefined, 'Spanish'), undefined)
  assert.equal(namedExport(SPLIT, 'French'), undefined)
})
