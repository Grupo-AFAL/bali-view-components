describe('DrawerController', () => {
  context('turbo_stream form submit', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/turbo_stream_form')
    })

    it('applies the turbo stream response and closes the drawer', () => {
      cy.intercept('POST', '/fake/submit*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: `
          <turbo-stream action="append" target="stream-target">
            <template><p id="stream-result">It worked</p></template>
          </turbo-stream>
        `
      }).as('submit')

      cy.get('.drawer-open').should('exist')
      cy.get('[data-action="drawer#submit"]').click()
      cy.wait('@submit')

      // The stream is applied to the page...
      cy.get('#stream-result').should('have.text', 'It worked')
      // ...not injected as inert markup inside the drawer
      cy.get('turbo-stream').should('not.exist')
      // ...and the drawer closes
      cy.get('.drawer-open').should('not.exist')
    })

    it('keeps HTML error responses inside the drawer (unchanged behavior)', () => {
      cy.intercept('POST', '/fake/submit*', {
        statusCode: 422,
        headers: { 'Content-Type': 'text/html' },
        body: '<form action="/fake/submit" data-turbo="true"><p id="form-error">Name is required</p></form>'
      }).as('submit')

      cy.get('[data-action="drawer#submit"]').click()
      cy.wait('@submit')

      // Error form re-renders inside the drawer, which stays open
      cy.get('.drawer-open').should('exist')
      cy.get('.drawer-open #form-error').should('have.text', 'Name is required')
    })
  })
})
