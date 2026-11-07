import { test } from 'node:test'
import assert from 'node:assert/strict'
import { commonJs } from '../../app/assets/javascripts/bali/utils/common-js.js'

// The two namespaces esbuild gave `import('flatpickr/dist/l10n/es.js')`, measured: unsplit the
// names are copied onto it next to the module's own `default`; split it holds only `default`,
// which is `module.exports`.
const Spanish = { rangeSeparator: ' a ' }
const moduleExports = { Spanish, default: { es: Spanish } }
const UNSPLIT = { Spanish, default: moduleExports.default }
const SPLIT = { default: moduleExports }

test('returns an unsplit namespace as it is', () => {
  assert.equal(commonJs(UNSPLIT, 'Spanish'), UNSPLIT)
})

test('returns module.exports from a split namespace', () => {
  assert.equal(commonJs(SPLIT, 'Spanish'), moduleExports)
})

test('is undefined for a missing module, without throwing', () => {
  assert.equal(commonJs(undefined, 'Spanish'), undefined)
})
