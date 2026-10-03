// Chromium's accessibility tree over CDP: what a screen reader is handed, and the only place
// the name of a widget that hides the element it was given (SlimSelect, flatpickr) can be read.
export const cdp = (command, params = {}) =>
  Cypress.automation('remote:debugger:protocol', { command, params })

// The page under test is an iframe of the runner, and a CDP call that takes a frame wants
// that one: the frame whose URL is `cy.url()`.
export const frameAt = (tree, url) =>
  tree.frame.url === url
    ? tree.frame
    : (tree.childFrames || []).map((child) => frameAt(child, url)).find(Boolean)
