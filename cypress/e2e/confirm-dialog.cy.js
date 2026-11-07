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

  // #1532 — Turbo submits a link with a method through a <form> it builds, which copies no
  // `data-bali-confirm-*`, and asks for the confirm with no submitter.
  describe('a link with a method', () => {
    it('takes the title, accept label and variant off the link', () => {
      cy.intercept('POST', '**/lookbook/noop').as('noop')
      cy.contains('a[data-turbo-method="post"]', 'Return the role').click()

      cy.get('dialog.modal[open] #bali-confirm-title').should('have.text', 'Return the role')
      cy.get('#bali-confirm-message').should('have.text', 'Return the role to its holder?')
      cy.get('#bali-confirm-accept-btn')
        .should('have.class', 'btn-warning')
        .and('have.text', 'Return it')
        .click()

      cy.wait('@noop')
    })

    // A later confirm with no submitter (Modal's confirm-on-close) asks its own question, so
    // the link's labels stay with the link. The first dialog closes without a click, as
    // Escape closes it, since a click would forget the link on its own.
    it('leaves its labels off a later confirm that asks something else', () => {
      cy.contains('a[data-turbo-method="post"]', 'Return the role').click()
      cy.get('dialog.modal[open] #bali-confirm-title').should('have.text', 'Return the role')
      // The dialog's own `close` listener, added first, is what lets the next confirm open.
      cy.get('dialog.modal[open]').then($dialog => new Cypress.Promise(resolve => {
        $dialog[0].addEventListener('close', resolve, { once: true })
        $dialog[0].close()
      }))

      cy.window().then(win => { win.Turbo.config.forms.confirm('Discard your changes?') })
      cy.get('dialog.modal[open] #bali-confirm-message').should('have.text', 'Discard your changes?')
      cy.get('#bali-confirm-title').should('have.prop', 'hidden', true)
      cy.get('#bali-confirm-accept-btn')
        .should('have.class', 'btn-primary')
        .and('not.have.text', 'Return it')
    })
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

// #1521 — DeleteLink's form carries "Confirm deletion" / "Delete" / danger; the caller's `data:`
// lands on the button, which the dialog reads first.
describe('DeleteLink confirm labels', () => {
  it('takes the title, accept label and variant the caller puts in data:', () => {
    cy.visit('/bali/delete_link/with_custom_confirm?custom_confirm=Remove%20HILLO%20from%20Juan%3F' +
             '&title=Remove%20assignment&accept=Remove&variant=warning')
    cy.contains('form.bali-delete-link-form button', 'Delete').click()

    cy.get('dialog.modal[open] #bali-confirm-title').should('have.text', 'Remove assignment')
    cy.get('#bali-confirm-message').should('have.text', 'Remove HILLO from Juan?')
    cy.get('#bali-confirm-accept-btn')
      .should('have.class', 'btn-warning')
      .and('have.text', 'Remove')
  })
})
