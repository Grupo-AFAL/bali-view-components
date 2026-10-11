// A SlimSelect rendered with the page inside a Modal or Drawer that is still closed connects
// before its `<dialog>` is shown with `showModal()`, when there is no top layer to join. Its
// list has to join it when it opens: left under <body> it opens beneath the panel and inert,
// so a click on an option lands on the panel and the search box never takes the focus.
// `top-layer-popups.cy.js` covers a dialog that is already open when the field connects.
describe('SlimSelect inside a Modal or Drawer rendered closed', () => {
  const PANELS = {
    Modal: { trigger: '[data-modal-id="slim-select-modal"]', dialog: '#slim-select-modal', prefix: 'modal' },
    Drawer: { trigger: '[data-drawer-id="slim-select-drawer"]', dialog: '#slim-select-drawer', prefix: 'drawer' }
  }

  // What a real click reaches. `cy.click()` would refuse a covered option too, but with
  // its own message; this one names the option and the reason.
  const isTopmostAtItsCentre = $option => {
    const option = $option[0]
    const rect = option.getBoundingClientRect()
    const hit = option.ownerDocument.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)

    expect(option.contains(hit), `"${option.textContent.trim()}" is the topmost element at its centre`).to.equal(true)
  }

  Object.entries(PANELS).forEach(([name, { trigger, dialog, prefix }]) => {
    context(name, () => {
      const openPanel = () => {
        cy.get(trigger).click()
        cy.get(dialog).should($dialog => expect($dialog[0].matches(':modal'), ':modal').to.equal(true))
      }

      const openList = attribute =>
        cy.get(`${dialog} .slim-select:has(#${prefix}_form_record_${attribute}) .ss-main`).click()

      beforeEach(() => {
        cy.visit('/bali/form/slim_select/in_dialog')
        cy.get(`${dialog} .ss-main`).should('have.length', 2)
      })

      it('lets an option of a local list be picked with a click', () => {
        openPanel()
        openList('select')

        cy.get('.ss-content.ss-open .ss-option').contains('Option 4').should(isTopmostAtItsCentre).click()
        cy.get(`#${prefix}_form_record_select`).should('have.value', '4')
      })

      it('types into the search box of a remote list and picks a result', () => {
        openPanel()
        openList('name')

        cy.document().its('activeElement').should('match', '.ss-content.ss-open .ss-search input')
        cy.focused().type('Jane')
        cy.get('.ss-content.ss-open .ss-option').contains('Jane Smith').should(isTopmostAtItsCentre).click()
        cy.get(`#${prefix}_form_record_name`).should('have.value', '4')
      })

      // SlimSelect closes its list on Escape and lets the keystroke bubble on to the panel.
      it('closes the list on the first Escape and the panel on the second', () => {
        openPanel()
        openList('select')
        cy.get('.ss-content.ss-open').should('exist')

        cy.focused().type('{esc}')
        cy.get('.ss-content.ss-open').should('not.exist')
        cy.get(dialog).should($dialog => expect($dialog[0].matches(':modal'), 'the panel is still open').to.equal(true))

        cy.focused().type('{esc}')
        cy.get(dialog).should($dialog => expect($dialog[0].open, 'open').to.equal(false))
      })

      // Closing the Modal swaps its content back in, so every select inside reconnects while
      // the dialog is closed again.
      it('opens on top again after the panel is closed and reopened', () => {
        openPanel()
        cy.get(`${dialog} button[aria-label][data-action$="#close"]`).click()
        cy.get(dialog).should($dialog => expect($dialog[0].open, 'open').to.equal(false))
        openPanel()
        openList('select')

        cy.get('.ss-content.ss-open .ss-option').contains('Option 2').should(isTopmostAtItsCentre).click()
        cy.get(`#${prefix}_form_record_select`).should('have.value', '2')
      })
    })
  })

  // A Drawer asks before discarding unsaved changes. A search typed in the list is not one;
  // a picked option is.
  context('Drawer with unsaved changes', () => {
    const { trigger, dialog } = PANELS.Drawer
    const combobox = `${dialog} .slim-select:has(#drawer_form_record_select) .ss-main`
    const closeButton = `${dialog} button[aria-label][data-action$="#close"]`

    beforeEach(() => {
      cy.visit('/bali/form/slim_select/in_dialog')
      cy.get(`${dialog} .ss-main`).should('have.length', 2)
      cy.get(trigger).click()
      cy.get(dialog).should($dialog => expect($dialog[0].matches(':modal'), ':modal').to.equal(true))
      cy.get(combobox).click()
    })

    it('closes without asking after a search typed in the list', () => {
      cy.focused().type('Option')
      cy.get(combobox).click()
      cy.get(closeButton).click()

      cy.get(dialog).should($dialog => expect($dialog[0].open, 'closed without asking').to.equal(false))
    })

    it('asks before closing once an option is picked', () => {
      cy.get('.ss-content.ss-open .ss-option').contains('Option 4').click()
      cy.get(closeButton).click()

      cy.get('#bali-confirm-accept-btn').should('be.visible')
      cy.get(dialog).should($dialog => expect($dialog[0].open, 'open').to.equal(true))
    })
  })
})
