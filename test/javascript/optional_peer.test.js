import { afterEach, beforeEach, describe, mock, test } from 'node:test'
import assert from 'node:assert/strict'
import { optionalPeer } from '../../app/assets/javascripts/bali/utils/optional-peer.js'

// Each browser's own words for the two failures, measured with Playwright in
// Chromium 148 and Firefox 150 (#1589).
const CHUNK = 'https://app.test/assets/chunks/peer.esm-HLS5FS2T.digested.js'
const DID_NOT_LOAD = {
  chromium: `Failed to fetch dynamically imported module: ${CHUNK}`,
  firefox: `error loading dynamically imported module: ${CHUNK}`
}
const NOT_INSTALLED = {
  chromium: "Failed to resolve module specifier 'tippy.js'",
  firefox: 'The specifier “tippy.js” was a bare specifier, but was not remapped to anything. ' +
    'Relative module specifiers must start with “./”, “../” or “/”.'
}

let consoleError
let reportError

beforeEach(() => {
  consoleError = mock.method(console, 'error', () => {})
  reportError = mock.fn()
  globalThis.reportError = reportError
})

afterEach(() => {
  consoleError.mock.restore()
  delete globalThis.reportError
})

// Reported packages are remembered for the page, so each test names its own.
describe('a chunk that did not load', () => {
  for (const [browser, message] of Object.entries(DID_NOT_LOAD)) {
    test(`is reported as an error with the failure as its cause, in ${browser}`, () => {
      const packageName = `${browser}-peer`
      const failure = new TypeError(message)

      assert.equal(optionalPeer(packageName)(failure), null)

      assert.equal(reportError.mock.callCount(), 1)
      const [reported] = reportError.mock.calls[0].arguments
      assert.match(reported.message, new RegExp(`\`${packageName}\` npm package is installed`))
      assert.equal(reported.cause, failure)
      assert.equal(consoleError.mock.callCount(), 0)
    })
  }

  test('is reported once per package, however many instances asked for it', () => {
    const failure = () => new TypeError(DID_NOT_LOAD.chromium)

    for (let i = 0; i < 4; i++) assert.equal(optionalPeer('repeated-peer')(failure()), null)
    optionalPeer('another-peer')(failure())

    assert.deepEqual(
      reportError.mock.calls.map((call) => call.arguments[0].message.match(/`([^`]+)`/)[1]),
      ['repeated-peer', 'another-peer']
    )
  })
})

describe('a package that is not installed', () => {
  for (const [browser, message] of Object.entries(NOT_INSTALLED)) {
    test(`asks for yarn add in the console, in ${browser}`, () => {
      assert.equal(optionalPeer('tippy.js')(new TypeError(message)), null)

      assert.equal(consoleError.mock.callCount(), 1)
      assert.match(consoleError.mock.calls[0].arguments[0], /Run `yarn add tippy\.js`/)
      assert.equal(reportError.mock.callCount(), 0)
    })
  }
})

test('a package that throws while evaluating is said to be installed, in the console', () => {
  assert.equal(optionalPeer('tippy.js')(new ReferenceError('window is not defined')), null)

  assert.equal(consoleError.mock.callCount(), 1)
  assert.match(consoleError.mock.calls[0].arguments[0], /IS installed but threw while evaluating/)
  assert.equal(reportError.mock.callCount(), 0)
})
