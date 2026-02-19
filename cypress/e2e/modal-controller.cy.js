describe('ModalController', () => {
  context('form modal', () => {
    beforeEach(() => {
      cy.visit('/bali/modal/form_modal')
    })

    it('stays open when a synthetic keydown fires (browser autocomplete)', () => {
      // Verify modal is visible
      cy.get('.modal-open').should('exist')
      cy.get('.modal-box input#name').should('be.visible')

      // Focus the input and type something
      cy.get('.modal-box input#name').click().type('test')

      // Simulate what browsers do when selecting an autocomplete suggestion:
      // a keydown event with key: undefined is dispatched on the input
      cy.get('.modal-box input#name').then($input => {
        $input[0].dispatchEvent(new Event('keydown', { bubbles: true, cancelable: true }))
      })

      // Modal should still be open
      cy.get('.modal-open').should('exist')
      cy.get('.modal-box input#name').should('be.visible')
    })

    it('closes when pressing Escape key', () => {
      cy.get('.modal-open').should('exist')

      // Press Escape key
      cy.get('.modal-box input#name').type('{esc}')

      // Modal should be closed
      cy.get('.modal-open').should('not.exist')
    })

    it('stays open when clicking inside the modal box', () => {
      cy.get('.modal-open').should('exist')

      // Click on the input inside the modal
      cy.get('.modal-box input#name').click()

      // Modal should still be open
      cy.get('.modal-open').should('exist')
    })
  })
})
