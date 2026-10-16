describe('CheckboxRevealController', () => {
  // checkbox-reveal has no preview of its own: any page that boots Bali's controllers will do.
  beforeEach(() => {
    cy.visit('/bali/checkbox_toggle/required_fields')
    cy.document().then(doc => doc.body.insertAdjacentHTML('beforeend', `
      <div data-controller="checkbox-reveal">
        <input type="checkbox" data-checkbox-reveal-target="checkbox" data-action="checkbox-reveal#toggle"
               data-testid="reveal">
        <div id="revealed" class="hidden" data-checkbox-reveal-target="item" data-testid="revealed"></div>
      </div>`))
  })

  // The server repaints the item as it last saw the form, unchecked. A morph keeps the
  // element, and Turbo applies a stream on the next frame: assertions wait for `data-streamed`.
  it('applies the checkbox on screen to an item a Turbo Stream morphs', () => {
    cy.get('[data-testid="reveal"]').check()
    cy.get('[data-testid="revealed"]').should('not.have.class', 'hidden')

    cy.window().then(win => win.Turbo.renderStreamMessage(`
      <turbo-stream action="replace" method="morph" target="revealed"><template>
        <div id="revealed" class="hidden" data-checkbox-reveal-target="item" data-testid="revealed" data-streamed></div>
      </template></turbo-stream>`))

    cy.get('[data-testid="revealed"][data-streamed]').should('not.have.class', 'hidden')
  })
})
