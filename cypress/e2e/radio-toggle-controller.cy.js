describe('RadioToggleController', () => {
  const target = name => cy.get(`[data-testid="${name}"]`)
  const radio = label => cy.contains('label', label).find('input[type="radio"]')

  context('the base case', () => {
    beforeEach(() => cy.visit('/bali/radio_toggle/default'))

    it('shows the target of the current value on connect', () => {
      target('pickup').should('not.have.class', 'hidden')
      target('delivery').should('have.class', 'hidden')
      target('address').should('have.class', 'hidden')
    })

    it('shows a target that lists the chosen value among several', () => {
      radio('Courier').check()
      target('pickup').should('have.class', 'hidden')
      target('delivery').should('have.class', 'hidden')
      target('address').should('not.have.class', 'hidden')

      radio('Home delivery').check()
      target('delivery').should('not.have.class', 'hidden')
      target('address').should('not.have.class', 'hidden')
    })
  })

  context('dependent fields', () => {
    const box = () => cy.contains('label', "I can't find the serial number").find('input[type="checkbox"]')
    const fields = name => target(name).find('input:not([type="hidden"]), textarea')
    const allDisabled = name => fields(name).each($field => expect($field, name).to.be.disabled)
    const allEnabled = name => fields(name).each($field => expect($field, name).to.be.enabled)

    // Turbo applies a stream on the next frame, so a test waits for the replacement
    // (`data-streamed`) before asserting on it — the old node would pass just as well.
    const stream = html => cy.window().then(win => win.Turbo.renderStreamMessage(html))

    beforeEach(() => cy.visit('/bali/radio_toggle/dependent_fields'))

    it('disables every target hidden on connect', () => {
      ;['damaged', 'label-photo', 'lost'].forEach((name) => {
        target(name).should('have.class', 'hidden')
        allDisabled(name)
      })
    })

    it('enables a target when it shows, and disables it when it hides', () => {
      radio('Lost').check()
      allEnabled('lost')

      radio('Damaged').check()
      allDisabled('lost')
      allEnabled('damaged')
    })

    it('needs the radio and the checkbox for a target joined with +', () => {
      radio('Damaged').check()
      target('label-photo').should('have.class', 'hidden')

      box().check()
      target('label-photo').should('not.have.class', 'hidden')
      allEnabled('label-photo')

      box().uncheck()
      target('label-photo').should('have.class', 'hidden')
    })

    it('keeps a + target hidden with the checkbox alone', () => {
      radio('Damaged').check()
      box().check()
      radio('Lost').check()

      target('label-photo').should('have.class', 'hidden')
    })

    it('sends only the fields that were on screen', () => {
      radio('Lost').check()
      cy.contains('label', 'Where was it last seen?').parent().find('textarea').type('Loading dock')
      radio('Damaged').check()
      cy.contains('label', 'What is damaged?').parent().find('input').type('Cracked screen')

      cy.contains('button', 'Send').click()

      cy.get('[data-testid="query"]').should('contain', 'damage_notes%5D=Cracked+screen')
      cy.get('[data-testid="query"]').should('not.contain', 'last_seen')
    })

    it('keeps a chosen file across a trip to another option', () => {
      radio('Damaged').check()
      box().check()
      // `force`: Bali's file field hides the native input behind its own button.
      fields('label-photo').selectFile({ contents: Cypress.Buffer.from('jpeg'), fileName: 'label.jpg' }, { force: true })

      radio('Lost').check()
      allDisabled('label-photo')

      radio('Damaged').check()
      allEnabled('label-photo')
      fields('label-photo').its('0.files').should('have.length', 1)
    })

    // The server repaints both targets as it last saw the form ("Working"): the photo
    // hidden and the lost panel shown, both behind the radio on screen.
    it('applies the current choice to a target a Turbo Stream replaces', () => {
      radio('Damaged').check()
      box().check()

      stream(`
        <turbo-stream action="replace" target="terminal-label-photo"><template>
          <fieldset id="terminal-label-photo" data-testid="label-photo" data-streamed class="hidden" disabled
                    data-radio-toggle-target="element" data-radio-toggle-value="damaged+serial_unknown">
            <input type="file" name="terminal[label_photo]">
          </fieldset>
        </template></turbo-stream>
        <turbo-stream action="replace" target="terminal-lost"><template>
          <fieldset id="terminal-lost" data-testid="lost" data-streamed
                    data-radio-toggle-target="element" data-radio-toggle-value="lost">
            <textarea name="terminal[last_seen]">from the server</textarea>
          </fieldset>
        </template></turbo-stream>`)

      cy.get('[data-testid="label-photo"][data-streamed]').should('not.have.class', 'hidden')
      allEnabled('label-photo')
      cy.get('[data-testid="lost"][data-streamed]').should('have.class', 'hidden')
      allDisabled('lost')
    })

    it('leaves a field the server disabled disabled when its target shows', () => {
      stream(`
        <turbo-stream action="replace" target="terminal-lost"><template>
          <fieldset id="terminal-lost" data-testid="lost" data-streamed
                    data-radio-toggle-target="element" data-radio-toggle-value="lost">
            <textarea name="terminal[last_seen]" disabled>read only</textarea>
          </fieldset>
        </template></turbo-stream>`)
      cy.get('[data-testid="lost"][data-streamed]').should('have.class', 'hidden')

      radio('Lost').check()
      target('lost').should('not.have.class', 'hidden')
      allDisabled('lost')
    })
  })
})
