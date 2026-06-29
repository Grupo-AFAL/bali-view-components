describe('Confirm dialog', () => {
  beforeEach(() => {
    cy.visit('/bali/confirm_dialog/default')
  })

  it('shows a styled dialog instead of the native confirm', () => {
    cy.contains('button', 'Eliminar registro').click()

    cy.get('dialog.modal[open]').should('be.visible')
    cy.get('#bali-confirm-title').should('have.text', 'Eliminar registro')
    cy.get('#bali-confirm-message').should('contain', 'eliminar este registro')
    cy.get('#bali-confirm-accept-btn')
      .should('have.class', 'btn-error')
      .and('have.text', 'Sí, eliminar')
  })

  it('cancelling closes the dialog without navigating', () => {
    cy.contains('button', 'Eliminar registro').click()
    cy.get('dialog.modal[open]').should('be.visible')

    cy.get('#bali-confirm-cancel-btn').click()
    cy.get('dialog.modal[open]').should('not.exist')
    cy.contains('button', 'Eliminar registro').should('be.visible')
  })

  it('confirming proceeds with the action', () => {
    cy.intercept('GET', '**/lookbook/preview/bali/confirm_dialog/default*').as('go')
    cy.contains('button', 'Publicar cambios').click()

    cy.get('dialog.modal[open]').should('be.visible')
    cy.get('#bali-confirm-accept-btn')
      .should('have.class', 'btn-info')
      .click()

    cy.wait('@go')
    cy.get('dialog.modal[open]').should('not.exist')
  })
})
