// ***********************************************************
// This example support/index.js is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

// Import commands.js using ES2015 syntax:
import './commands'

// Alternatively you can use CommonJS syntax:
// require('./commands')

// An aborted request is a cancelled navigation, not a failure of the page under
// test — and Turbo lets one escape as an unhandled rejection, which Cypress
// charges to whichever test was running.
//
// `FetchRequest#receive` calls its async delegate without awaiting it
// (@hotwired/turbo 8.0.23, `dist/turbo.es2017-esm.js:826`), and the delegate
// then awaits `FetchResponse#responseHTML` — `response.clone().text()`. Cancel
// the request between the headers and the body and that `text()` rejects with
// `AbortError` on a promise chain nobody holds; the `catch` in `perform()`
// that does ignore `AbortError` was detached two lines earlier. A frame cancels
// its previous request on every new navigation, so two quick clicks on two rows
// are enough.
//
// Measured on 8.0.23 + Cypress 16.1.0: `split-view.cy.js` "moves aria-current to
// the clicked row" aborts one of its four frame fetches and failed 5 runs out of
// 5 (#1180). Nothing is broken in the page — the frame shows the row clicked
// last — so the rejection is noise, and only this one is swallowed: an
// `AbortError` that arrives as a promise rejection. Every other uncaught error,
// and any `AbortError` thrown rather than rejected, still fails the test.
Cypress.on('uncaught:exception', (error, runnable, promise) => {
  if (promise && error?.name === 'AbortError') return false
})
