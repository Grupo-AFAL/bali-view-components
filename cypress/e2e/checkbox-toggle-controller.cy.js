describe('CheckboxToggleController', () => {
  const target = name => cy.get(`[data-testid="${name}"]`)
  const box = () => cy.contains('label', 'Public school registration fee').find('input[type="checkbox"]')
  // `force`: Bali's file field hides the native input behind its own button.
  const attachInvoice = () => cy.get('#expense_pdf_invoice')
    .selectFile({ contents: Cypress.Buffer.from('%PDF'), fileName: 'invoice.pdf' }, { force: true })

  // One side per stream: a callback that renders both sides would cover for the other.
  // Turbo applies a stream on the next frame, so assertions wait for `data-streamed`.
  const replace = (name, attributes) => cy.window().then(win => win.Turbo.renderStreamMessage(`
    <turbo-stream action="replace" targets="[data-testid='${name}']"><template>
      <fieldset data-testid="${name}" data-streamed ${attributes}><input type="file"></fieldset>
    </template></turbo-stream>`))
  const streamed = name => cy.get(`[data-testid="${name}"][data-streamed]`)

  context('with disable-hidden', () => {
    beforeEach(() => cy.visit('/bali/checkbox_toggle/required_fields'))

    it('disables the side hidden on connect', () => {
      target('receipts').should('have.class', 'hidden').and('be.disabled')
      target('invoice').should('not.have.class', 'hidden').and('be.enabled')
    })

    it('swaps which side is disabled as the checkbox changes', () => {
      box().check()
      target('invoice').should('have.class', 'hidden').and('be.disabled')
      target('receipts').should('not.have.class', 'hidden').and('be.enabled')

      box().uncheck()
      target('receipts').should('have.class', 'hidden').and('be.disabled')
      target('invoice').should('not.have.class', 'hidden').and('be.enabled')
    })

    // The server repaints each side as it last saw the form, unchecked.
    it('applies the checkbox on screen to each side a Turbo Stream replaces', () => {
      box().check()

      replace('receipts', 'class="hidden" disabled data-checkbox-toggle-target="on"')
      streamed('receipts').should('not.have.class', 'hidden').and('be.enabled')

      replace('invoice', 'data-checkbox-toggle-target="off"')
      streamed('invoice').should('have.class', 'hidden').and('be.disabled')
    })

    it('sends the form without the required file on the hidden side', () => {
      attachInvoice()
      cy.contains('button', 'Save').click()

      cy.get('[data-testid="query"]').should('contain', 'pdf_invoice%5D=invoice.pdf')
      cy.get('[data-testid="query"]').should('not.contain', 'receipts')
    })
  })

  context('without disable-hidden', () => {
    beforeEach(() => cy.visit('/bali/checkbox_toggle/required_fields?disable_hidden=false'))

    it('leaves the hidden side enabled, so its required file still stops the form', () => {
      attachInvoice()

      target('receipts').should('have.class', 'hidden').and('be.enabled')
      cy.get('form[data-controller="checkbox-toggle"]').should(($form) => {
        const invalid = [...$form[0].elements].filter(field => field.willValidate && !field.validity.valid)
        expect(invalid.map(field => field.name)).to.deep.equal(['expense[receipts][]'])
      })
    })

    it('applies the checkbox on screen to each side a Turbo Stream replaces', () => {
      box().check()

      replace('receipts', 'class="hidden" data-checkbox-toggle-target="on"')
      streamed('receipts').should('not.have.class', 'hidden')

      replace('invoice', 'data-checkbox-toggle-target="off"')
      streamed('invoice').should('have.class', 'hidden').and('be.enabled')
    })
  })

  context('with one target', () => {
    beforeEach(() => cy.visit('/bali/checkbox_toggle/required_fields'))

    // Both arrive in one mutation, so a controller that throws while connecting
    // would also keep the one after it from connecting.
    it('paints a controller that has only one of the two targets', () => {
      cy.document().then(doc => doc.body.insertAdjacentHTML('beforeend', `
        <div data-controller="checkbox-toggle" data-checkbox-toggle-checked-value="true">
          <div class="hidden" data-checkbox-toggle-target="on" data-testid="only-on"></div>
        </div>
        <div data-controller="checkbox-toggle" data-checkbox-toggle-checked-value="true">
          <div data-checkbox-toggle-target="off" data-testid="only-off"></div>
        </div>`))

      target('only-on').should('not.have.class', 'hidden')
      target('only-off').should('have.class', 'hidden')
    })
  })
})
