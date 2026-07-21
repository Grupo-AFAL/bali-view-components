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

  context('confirm on close (unsaved changes)', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/dirty_form')
      cy.get('.drawer-open').should('exist')
    })

    it('prompts before discarding an edited form on Escape; cancel keeps the values', () => {
      cy.get('#form_record_text').type('Hello')

      // Escape originates inside the drawer so it reaches the drawer#close action
      cy.get('#form_record_text').type('{esc}')

      // Confirmation dialog appears and the drawer stays open
      cy.get('dialog[data-bali-confirm]').should('be.visible')
      cy.get('.drawer-open').should('exist')

      // Cancelling keeps the drawer open with the typed value intact
      cy.get('#bali-confirm-cancel-btn').click()
      cy.get('.drawer-open').should('exist')
      cy.get('#form_record_text').should('have.value', 'Hello')

      // Escape again + accept closes the drawer
      cy.get('#form_record_text').type('{esc}')
      cy.get('#bali-confirm-accept-btn').click()
      cy.get('dialog[data-bali-confirm]').should('not.be.visible')
      cy.get('.drawer-open').should('not.exist')
    })

    it('closes without prompting when the form is untouched', () => {
      cy.get('#form_record_text').type('{esc}')

      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('not.exist')
    })
  })

  context('flatpickr calendar inside the drawer', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/dirty_form')
      cy.get('.drawer-open').should('exist')
    })

    it('first Escape closes the calendar, second Escape closes the (clean) drawer', () => {
      // flatpickr renders its calendar on document.body, outside the drawer DOM.
      // Its alt input is readonly, so Escape needs `force` to dispatch the keydown.
      cy.get('.flatpickr input').filter(':visible').first().click()
      cy.get('.flatpickr-calendar.open').should('exist')

      // First Escape: flatpickr consumes it and closes the calendar; drawer stays
      cy.get('.flatpickr input').filter(':visible').first().type('{esc}', { force: true })
      cy.get('.flatpickr-calendar.open').should('not.exist')
      cy.get('.drawer-open').should('exist')

      // Second Escape: form is still clean, so the drawer closes without a prompt
      cy.get('.flatpickr input').filter(':visible').first().type('{esc}', { force: true })
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('not.exist')
    })
  })
})
