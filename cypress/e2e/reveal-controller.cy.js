describe('RevealController', () => {
  context('show and hide', () => {
    beforeEach(() => {
      cy.visit('/bali/reveal/external_controls')
    })

    // show() used to REMOVE is-revealed and hide() used to ADD it, so the two
    // named methods did the opposite of what they say. Only toggle() worked.
    it('reveals on show', () => {
      cy.get('#external-item').should('not.be.visible')
      cy.contains('#external-controls button', 'Show').click()
      cy.get('#external-item').should('be.visible')
      cy.get('#external-controls').should('have.class', 'is-revealed')
    })

    it('hides on hide', () => {
      cy.contains('#external-controls button', 'Show').click()
      cy.get('#external-item').should('be.visible')

      cy.contains('#external-controls button', 'Hide').click()
      cy.get('#external-item').should('not.be.visible')
      cy.get('#external-controls').should('not.have.class', 'is-revealed')
    })

    it('is idempotent — showing twice leaves it shown', () => {
      cy.contains('#external-controls button', 'Show').click()
      cy.contains('#external-controls button', 'Show').click()
      cy.get('#external-item').should('be.visible')
    })

    it('is idempotent — hiding twice leaves it hidden', () => {
      cy.contains('#external-controls button', 'Show').click()
      cy.contains('#external-controls button', 'Hide').click()
      cy.contains('#external-controls button', 'Hide').click()
      cy.get('#external-item').should('not.be.visible')
    })

    it('agrees with toggle', () => {
      cy.contains('#external-controls button', 'Toggle').click()
      cy.get('#external-item').should('be.visible')
      cy.contains('#external-controls button', 'Toggle').click()
      cy.get('#external-item').should('not.be.visible')
    })
  })

  context('trigger', () => {
    beforeEach(() => {
      cy.visit('/bali/reveal/external_controls')
    })

    it('reveals the content it points at', () => {
      cy.get('#with-trigger .reveal-trigger').then(($trigger) => {
        const contentId = $trigger.attr('aria-controls')
        cy.get(`#${contentId}`).should('not.be.visible')
        cy.wrap($trigger).click()
        cy.get(`#${contentId}`).should('be.visible')
      })
    })

    it('is a button, so it is reachable and operable from the keyboard', () => {
      cy.get('#with-trigger .reveal-trigger')
        .should('match', 'button')
        .should('have.attr', 'type', 'button')
        .focus()
        .type('{enter}')

      cy.get('#with-trigger').should('have.class', 'is-revealed')
    })

    it('reports its state with aria-expanded', () => {
      cy.get('#with-trigger .reveal-trigger')
        .should('have.attr', 'aria-expanded', 'false')
        .click()
        .should('have.attr', 'aria-expanded', 'true')
        .click()
        .should('have.attr', 'aria-expanded', 'false')
    })
  })
})
