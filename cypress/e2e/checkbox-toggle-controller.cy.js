describe('CheckboxToggleController', () => {
  const target = name => cy.get(`[data-testid="${name}"]`)
  const box = () => cy.contains('label', 'Public school registration fee').find('input[type="checkbox"]')
  // `force`: Bali's file field hides the native input behind its own button.
  const attachInvoice = () => cy.get('#expense_pdf_invoice')
    .selectFile({ contents: Cypress.Buffer.from('%PDF'), fileName: 'invoice.pdf' }, { force: true })

  // One side per stream: a callback that renders both sides would cover for the other.
  // Turbo applies a stream on the next frame, so assertions wait for `data-streamed`.
  const replace = (name, attributes, method) => cy.window().then(win => win.Turbo.renderStreamMessage(`
    <turbo-stream action="replace" ${method} targets="[data-testid='${name}']"><template>
      <fieldset data-testid="${name}" data-streamed ${attributes}><input type="file"></fieldset>
    </template></turbo-stream>`))
  const streamed = name => cy.get(`[data-testid="${name}"][data-streamed]`)
  // A morph keeps the element, so no target callback runs for it.
  const streams = { replaces: '', morphs: 'method="morph"' }

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
    Object.entries(streams).forEach(([verb, method]) => {
      it(`applies the checkbox on screen to each side a Turbo Stream ${verb}`, () => {
        box().check()

        replace('receipts', 'class="hidden" disabled data-checkbox-toggle-target="on"', method)
        streamed('receipts').should('not.have.class', 'hidden').and('be.enabled')

        replace('invoice', 'data-checkbox-toggle-target="off"', method)
        streamed('invoice').should('have.class', 'hidden').and('be.disabled')
      })
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

    Object.entries(streams).forEach(([verb, method]) => {
      it(`applies the checkbox on screen to each side a Turbo Stream ${verb}`, () => {
        box().check()

        replace('receipts', 'class="hidden" data-checkbox-toggle-target="on"', method)
        streamed('receipts').should('not.have.class', 'hidden')

        replace('invoice', 'data-checkbox-toggle-target="off"', method)
        streamed('invoice').should('have.class', 'hidden').and('be.enabled')
      })
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

  context('with several targets on each side', () => {
    beforeEach(() => cy.visit('/bali/checkbox_toggle/required_fields'))

    // One string per target: `have.class` and `be.disabled` pass if any one of them matches.
    const state = fieldset => `${fieldset.classList.contains('hidden') ? 'hidden' : 'shown'}${fieldset.disabled ? ' disabled' : ''}`
    const painted = (name, states) => target(name).should($fieldsets => expect([...$fieldsets].map(state)).to.deep.equal(states))

    ;[true, false].forEach((disableHidden) => {
      const hidden = disableHidden ? 'hidden disabled' : 'hidden'

      it(`paints every target of each side, disable-hidden ${disableHidden}`, () => {
        cy.document().then(doc => doc.body.insertAdjacentHTML('beforeend', `
          <div data-controller="checkbox-toggle" data-checkbox-toggle-disable-hidden-value="${disableHidden}">
            <input type="checkbox" data-action="checkbox-toggle#change" data-testid="several">
            <fieldset data-checkbox-toggle-target="on" data-testid="on"></fieldset>
            <fieldset data-checkbox-toggle-target="off" data-testid="off"></fieldset>
            <fieldset data-checkbox-toggle-target="on" data-testid="on"></fieldset>
            <fieldset data-checkbox-toggle-target="off" data-testid="off"></fieldset>
          </div>`))

        painted('on', [hidden, hidden])
        painted('off', ['shown', 'shown'])

        target('several').check()
        painted('on', ['shown', 'shown'])
        painted('off', [hidden, hidden])
      })
    })
  })
})
