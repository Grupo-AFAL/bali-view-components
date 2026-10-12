// Chrome reports a ResizeObserver whose callback resized what it observes as an error on the
// window, though by the spec nothing is lost: what the observer held back is delivered in the next
// frame. The report failed `base-surface-steps.cy.js` twice in full runs, opening the Gantt's
// menus, and `gantt-island.cy.js` twice in CI, dragging a phone board's splitter back — and
// neither spec in 20 to 30 runs of it alone. Where it comes from is not known.
//
// Let through per test, never suite-wide: `toolbar_overflow_controller.js` and the Gantt's
// `Toolbar.jsx` (its separator observer) defer their measurement a frame to avoid this loop, and
// the error failing a test is their only guard. Cypress rewrites the message and quotes the page's
// between blank lines, so only that block, word for word, is let through.
const RESIZE_OBSERVER_LOOP = /\n\n {2}> ResizeObserver loop completed with undelivered notifications\.\n\n/

export const allowResizeObserverLoop = () =>
  cy.on('uncaught:exception', (error) => !RESIZE_OBSERVER_LOOP.test(error.message))
