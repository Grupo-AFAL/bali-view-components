// The dummy builds with code splitting, as the apps do, so a library Bali loads with `import()`
// arrives in a chunk of its own after the page is interactive. `holdChunk('tippy.esm')` keeps
// that chunk at the proxy until `release()` runs, so a spec can act in the window a real user
// has on a slow network. `name` is the module's file name, which esbuild puts in front of the
// chunk's hash (`chunks/tippy.esm-HLS5FS2T.digested.js`).
//
// Propshaft serves chunks as immutable, so one an earlier test loaded comes out of the HTTP
// cache and never reaches the proxy: the cache is cleared first.
export const holdChunk = (name) => {
  const held = { requested: false }
  let release
  const released = new Promise(resolve => { release = resolve })
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

  cy.then(() => Cypress.automation('remote:debugger:protocol', { command: 'Network.clearBrowserCache' }))
  cy.intercept({ method: 'GET', url: new RegExp(`/chunks/${escaped}-[^/]+\\.js$`) }, req => {
    held.requested = true
    return released.then(() => req.continue())
  })

  return {
    // Proves the module is not in the page yet: its request is the one being held.
    requested: () => cy.wrap(held).its('requested').should('equal', true),
    release: () => cy.then(() => release())
  }
}
