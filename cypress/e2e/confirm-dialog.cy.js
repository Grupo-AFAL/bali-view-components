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

  it('dismissing via the backdrop closes without navigating', () => {
    cy.contains('button', 'Eliminar registro').click()
    cy.get('dialog.modal[open]').should('be.visible')

    cy.get('dialog.modal .modal-backdrop button').click({ force: true })
    cy.get('dialog.modal[open]').should('not.exist')
    cy.contains('button', 'Eliminar registro').should('be.visible')
  })

  // #1409 — the labels of a trigger that sets none, in the language of the page.
  describe('button labels', () => {
    const openIn = (lang, trigger) => {
      cy.document().then(doc => { doc.documentElement.lang = lang })
      cy.contains('button', trigger).click()
    }
    const expectLabels = (accept, cancel) => {
      cy.get('dialog.modal[open] #bali-confirm-accept-btn').should('have.text', accept)
      cy.get('dialog.modal[open] #bali-confirm-cancel-btn').should('have.text', cancel)
    }
    const cancel = () => {
      cy.get('#bali-confirm-cancel-btn').click()
      cy.get('dialog.modal[open]').should('not.exist')
    }

    // The language changes after `registerAll` installed the dialog, as a Turbo visit
    // changes it, so it has to be read when the dialog opens. costa-norte writes
    // `lang="<%= I18n.locale %>"` with `es-MX` as its default.
    it('follow the page language on a bare data-turbo-confirm', () => {
      openIn('es', 'Guardar')
      expectLabels('Aceptar', 'Cancelar')
      cancel()

      openIn('en', 'Guardar')
      expectLabels('OK', 'Cancel')
      cancel()

      openIn('es-MX', 'Guardar')
      expectLabels('Aceptar', 'Cancelar')
    })

    it('keep a label the trigger sets, beside one that follows the page language', () => {
      openIn('es', 'Publicar cambios')
      expectLabels('Publicar', 'Cancelar')
    })

    it('keep the labels given to installConfirmDialog in any language', () => {
      cy.window().then(win => win.installConfirmDialog({ acceptText: 'Proceed', cancelText: 'Go back' }))

      openIn('es', 'Guardar')
      expectLabels('Proceed', 'Go back')
    })
  })

  it('still works after a Turbo navigation (singleton re-attaches to the new body)', () => {
    // Accepting triggers a Turbo Drive GET visit that replaces document.body,
    // detaching the singleton dialog. The next confirm must rebuild it.
    cy.contains('button', 'Guardar').click()
    cy.get('#bali-confirm-accept-btn').click()

    // Page re-rendered after the Turbo visit
    cy.contains('button', 'Eliminar registro').should('be.visible')

    // Confirm again — dialog must still appear (regression guard for the detach bug)
    cy.contains('button', 'Eliminar registro').click()
    cy.get('dialog.modal[open]').should('be.visible')
    cy.get('#bali-confirm-title').should('have.text', 'Eliminar registro')
  })
})
