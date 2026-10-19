import { test, mock } from 'node:test'
import assert from 'node:assert/strict'
import { islandStrings, announceTables, I18N_TABLES_HEADER } from '../../app/components/bali/bpmn_editor/i18n.js'

// The tables Component#i18n_table_tag writes, as far as islandStrings reads
// them: a node answers querySelector for its own scripts and lists its
// <template>s, whose `content` is another such node.
const SCRIPT = /^script\[type="application\/json"\]\[data-bali-bpmn-i18n="([^"]+)"\]$/
function node ({ scripts = {}, templates = [] } = {}) {
  return {
    querySelector (selector) {
      const key = selector.match(SCRIPT)?.[1]
      return key && key in scripts ? { textContent: scripts[key] } : null
    },
    querySelectorAll: (selector) => (selector === 'template' ? templates.map((content) => ({ content })) : [])
  }
}
const withDocument = (doc, fn) => {
  globalThis.document = doc
  try { return fn() } finally { delete globalThis.document }
}

test('reads the table the key names, and serves it from memory afterwards', () => {
  const table = withDocument(node({ scripts: { k1: '{"palette_title":"Elementos"}' } }), () => islandStrings('k1'))
  assert.equal(table.palette_title, 'Elementos')
  // The script is gone (a frame replaced it): the cached table still serves.
  assert.equal(withDocument(node(), () => islandStrings('k1')), table)
})

test('looks in the editor itself first, then inside <template> contents', () => {
  const element = node({ scripts: { k2: '{"palette_title":"Own"}' } })
  assert.equal(withDocument(node(), () => islandStrings('k2', { element })).palette_title, 'Own')

  const nested = node({ templates: [node({ templates: [node({ scripts: { k3: '{"palette_title":"Cloned"}' } })] })] })
  assert.equal(withDocument(nested, () => islandStrings('k3')).palette_title, 'Cloned')
})

test('without the table: the inline fallback, and one warning per key', () => {
  const warn = mock.method(console, 'warn', () => {})
  try {
    const fallback = { palette_title: 'Inline' }
    assert.equal(withDocument(node(), () => islandStrings('gone', { fallback })), fallback)
    assert.deepEqual(withDocument(node(), () => islandStrings('gone')), {})
    assert.equal(warn.mock.callCount(), 1)
  } finally {
    warn.mock.restore()
  }
})

test('no key: the inline table as it was', () => {
  const fallback = { palette_title: 'Inline' }
  assert.equal(islandStrings('', { fallback }), fallback)
})

test('a Turbo fetch names the tables the page holds, to its own origin only', () => {
  globalThis.window = { location: { origin: 'https://app.test' } }
  try {
    withDocument(node({ scripts: { held: '{}' } }), () => islandStrings('held'))
    const fetchTo = (href) => ({ detail: { url: new URL(href), fetchOptions: { headers: {} } } })

    const own = fetchTo('https://app.test/flows/1')
    announceTables(own)
    assert.match(own.detail.fetchOptions.headers[I18N_TABLES_HEADER], /(^|,)held(,|$)/)

    const other = fetchTo('https://elsewhere.test/flows/1')
    announceTables(other)
    assert.deepEqual(other.detail.fetchOptions.headers, {})
  } finally {
    delete globalThis.window
  }
})
