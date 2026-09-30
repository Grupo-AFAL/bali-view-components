// `radio-toggle` has no component of its own: the previews are hand markup over the
// FormBuilder, the same shape a host writes.
describe('radio-toggle controller', () => {
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

    beforeEach(() => cy.visit('/bali/radio_toggle/dependent_fields'))

    it('disables the fields of every target hidden on connect', () => {
      ;['damaged', 'label-photo', 'lost'].forEach((name) => {
        target(name).should('have.class', 'hidden')
        fields(name).each($field => expect($field, name).to.be.disabled)
      })
    })

    it('enables the fields of a target when it shows, and disables them when it hides', () => {
      radio('Lost').check()
      fields('lost').should('be.enabled')

      radio('Damaged').check()
      fields('lost').should('be.disabled')
      fields('damaged').should('be.enabled')
    })

    it('needs the radio and the checkbox for a target joined with +', () => {
      radio('Damaged').check()
      target('label-photo').should('have.class', 'hidden')

      box().check()
      target('label-photo').should('not.have.class', 'hidden')
      fields('label-photo').should('be.enabled')

      box().uncheck()
      target('label-photo').should('have.class', 'hidden')

      // The checkbox alone is not enough either.
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

    // Disabling rather than emptying is the point: a user who chose a file and wandered
    // off to another option finds it still there on the way back.
    it('keeps a chosen file across a trip to another option', () => {
      radio('Damaged').check()
      box().check()
      // `force`: Bali's file field hides the native input behind its own button.
      fields('label-photo').selectFile({ contents: Cypress.Buffer.from('jpeg'), fileName: 'label.jpg' }, { force: true })

      radio('Lost').check()
      fields('label-photo').should('be.disabled')

      radio('Damaged').check()
      fields('label-photo').should('be.enabled')
        .its('0.files').should('have.length', 1)
    })

    // A Turbo Stream repaints a target the way the server last saw the form, which can
    // be behind the radio on screen — here the server still thinks "Working".
    it('applies the current choice to a target a Turbo Stream replaces', () => {
      radio('Damaged').check()
      box().check()

      cy.window().then((win) => {
        win.Turbo.renderStreamMessage(`
          <turbo-stream action="replace" target="terminal-label-photo"><template>
            <div id="terminal-label-photo" data-testid="label-photo" class="hidden"
                 data-radio-toggle-target="element" data-radio-toggle-value="damaged+serial_unknown">
              <input type="file" name="terminal[label_photo]">
            </div>
          </template></turbo-stream>
          <turbo-stream action="replace" target="terminal-lost"><template>
            <div id="terminal-lost" data-testid="lost"
                 data-radio-toggle-target="element" data-radio-toggle-value="lost">
              <textarea name="terminal[last_seen]">from the server</textarea>
            </div>
          </template></turbo-stream>`)
      })

      target('label-photo').should('not.have.class', 'hidden')
      fields('label-photo').should('be.enabled')
      target('lost').should('have.class', 'hidden')
      fields('lost').should('be.disabled')
    })

    it('leaves a field the server disabled disabled when its target shows', () => {
      cy.window().then((win) => {
        win.Turbo.renderStreamMessage(`
          <turbo-stream action="replace" target="terminal-lost"><template>
            <div id="terminal-lost" data-testid="lost"
                 data-radio-toggle-target="element" data-radio-toggle-value="lost">
              <textarea name="terminal[last_seen]" disabled>read only</textarea>
            </div>
          </template></turbo-stream>`)
      })
      target('lost').should('have.class', 'hidden')

      radio('Lost').check()
      target('lost').should('not.have.class', 'hidden')
      fields('lost').should('be.disabled')
    })
  })
})
