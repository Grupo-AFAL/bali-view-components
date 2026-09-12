// The counter is the `textarea` controller, and #723 pointed it at an `<input>`
// as well: it only ever reads `value.length`, so the element it counts is not
// its business. These specs run the same expectations against both, because the
// point of the change is that there is one behaviour and not two.
describe('CharCounter', () => {
  const counter = () => cy.get('[data-textarea-target="counter"]').first()

  context('on a text field', () => {
    beforeEach(() => {
      cy.visit('/bali/form/text/with_char_counter')
    })

    it('counts from zero on connect', () => {
      counter().should('have.text', '0 / 40')
    })

    it('counts as the user types', () => {
      cy.get('#form_record_text').type('Hello')
      counter().should('have.text', '5 / 40')
    })

    it('counts back down on delete', () => {
      cy.get('#form_record_text').type('Hello')
      cy.get('#form_record_text').type('{backspace}{backspace}')
      counter().should('have.text', '3 / 40')
    })

    it('turns red past the maximum, without stopping the typing', () => {
      counter().should('not.have.class', 'text-error')

      cy.get('#form_record_text').type('x'.repeat(41), { delay: 0 })

      counter().should('have.text', '41 / 40')
      counter().should('have.class', 'text-error')
      cy.get('#form_record_text').should('have.value', 'x'.repeat(41))
    })

    it('just counts when no maximum was given', () => {
      cy.get('#form_record_url').type('abc')
      cy.get('[data-textarea-target="counter"]').last().should('have.text', '3')
    })
  })

  // `auto_grow` belongs to the textarea, and a text field written with it gets
  // the controller on its wrapper but no input target — the controller has to
  // stay quiet rather than throw on connect.
  context('auto_grow on a text field', () => {
    it('does nothing instead of erroring', () => {
      cy.visit('/bali/form/text/with_auto_grow', {
        onBeforeLoad (win) {
          cy.spy(win.console, 'error').as('consoleError')
        }
      })

      cy.get('#form_record_text').type('Hello')
      cy.get('#form_record_text').should('have.value', 'Hello')
      cy.get('@consoleError').should('not.have.been.called')
    })
  })

  context('on a textarea', () => {
    beforeEach(() => {
      cy.visit('/bali/form/text_area/default?char_counter=true&max_length=40')
    })

    it('counts as the user types', () => {
      cy.get('#form_record_text').type('Hello')
      counter().should('have.text', '5 / 40')
    })

    it('turns red past the maximum', () => {
      cy.get('#form_record_text').type('x'.repeat(41), { delay: 0 })
      counter().should('have.class', 'text-error')
    })
  })
})
