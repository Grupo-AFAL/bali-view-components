// #1589: in the split build every optional peer is a chunk of its own. When that file does not
// arrive, the browser's rejection is reported as an error wrapped around it — not logged as a
// package that is not installed. Asserted on the browser's real message, which the unit test
// (test/javascript/optional_peer.test.js) can only copy.
describe('optionalPeer, when a peer\'s chunk does not load', () => {
  it('reports the Tooltip\'s tippy.js chunk as an error, with the browser\'s failure as its cause', () => {
    // Read from the page's own `error` event, where an error tracker listens: the copy Cypress
    // hands `uncaught:exception` has no `cause`.
    const reported = []
    cy.on('uncaught:exception', () => false)
    cy.intercept('GET', '**/chunks/tippy.esm-*.js', { statusCode: 404, body: '' }).as('tippy')

    cy.visit('/bali/tooltip/default', {
      onBeforeLoad (win) {
        win.addEventListener('error', (event) => reported.push(event.error))
        cy.spy(win.console, 'error').as('consoleError')
      }
    })

    cy.wait('@tippy')
    cy.wrap(reported).should('have.length', 1)
    cy.wrap(reported).its('0.message').should('contain', '`tippy.js` npm package is installed')
    cy.wrap(reported).its('0.cause.message').should('match', /dynamically imported module/)
    cy.get('@consoleError').should('not.have.been.calledWithMatch', /yarn add/)
    cy.get('[data-tippy-root]').should('not.exist')
  })
})
