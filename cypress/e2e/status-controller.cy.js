describe('StatusController', () => {
  context('editable status pill', () => {
    beforeEach(() => {
      cy.visit('/bali/status/editable')
    })

    it('opens the options panel on click', () => {
      cy.get('.status-panel').should('not.be.visible')
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible')
      cy.get('.status-option[role="option"]').should('have.length.greaterThan', 1)
    })

    it('closes on Escape', () => {
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible')
      cy.get('body').type('{esc}')
      cy.get('.status-panel').first().should('not.be.visible')
    })

    it('closes on outside click', () => {
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible')
      cy.get('body').click('bottomRight')
      cy.get('.status-panel').first().should('not.be.visible')
    })

    // NOTE: `form_with method: :patch` renders <form method="post"> plus a
    // hidden _method=patch field, so the wire request is POST (Rack method
    // override), NOT PATCH. Intercept POST — matching the drawer spec. The
    // body carries `_method=patch` and the clicked button's name/value.
    it('submits the form with the chosen value when an option is selected', () => {
      cy.intercept('POST', '/lookbook*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: '<turbo-stream action="append" target="stream-target"><template><p id="stream-result">ok</p></template></turbo-stream>'
      }).as('submit')

      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-option[value="done"]').first().click()

      cy.wait('@submit').its('request.body').should('include', 'thing%5Bstatus%5D=done')
    })

    it('submits an empty value when the clear X is clicked', () => {
      cy.intercept('POST', '/lookbook*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: '<turbo-stream action="append" target="stream-target"><template><p>ok</p></template></turbo-stream>'
      }).as('clear')

      cy.get('.status-pill__clear').first().click({ force: true })
      // thing[status] is the last form param, so its empty value is followed by
      // end-of-body or the next '&' — match either, don't assume a trailing '&'.
      cy.wait('@clear').its('request.body').should('match', /thing%5Bstatus%5D=(&|$)/)
    })
  })

  context('inside an overflow container', () => {
    beforeEach(() => {
      cy.visit('/bali/status/in_table')
    })

    it('renders the panel above the table without clipping', () => {
      cy.get('[data-status-target="trigger"]').first().click()
      cy.get('.status-panel').first().should('be.visible').then(($panel) => {
        // position:fixed panels are laid out against the viewport, not the
        // overflow-x-auto ancestor, so the panel is not clipped.
        expect($panel[0].getBoundingClientRect().height).to.be.greaterThan(0)
      })
    })
  })
})
