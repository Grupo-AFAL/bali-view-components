// The keyboard half of the tooltip's default trigger never fired. tippy honours `focus`
// only when the focused element IS the reference, and the reference is the wrapper the
// template puts around the `trigger` slot — no tabindex, so it never took focus. Neither
// end of the slot contract worked: a focusable control inside it could not open the
// balloon, and a slot with nothing focusable in it had no keyboard route at all.
describe('TooltipController', () => {
  const balloon = '[data-tippy-root]'

  context('a slot that brings its own focusable control', () => {
    beforeEach(() => {
      cy.visit('/bali/tooltip/keyboard_reach')
    })

    it('opens on the control focus and closes when focus leaves', () => {
      cy.get(balloon).should('not.exist')

      cy.contains('button', 'Focusable trigger').focus()
      cy.get(balloon).should('be.visible')
        .and('contain', 'The button inside the slot is the tab stop')

      cy.contains('button', 'Focusable trigger').blur()
      cy.get(balloon).should('not.exist')
    })

    // The wrapper must not become a second, unnamed stop in front of the caller's button.
    it('leaves the wrapper out of the tab order', () => {
      cy.contains('button', 'Focusable trigger')
        .parents('.trigger')
        .should('not.have.attr', 'tabindex')
    })

    it('describes the control through the balloon it opens', () => {
      cy.contains('button', 'Focusable trigger').focus()
      cy.contains('button', 'Focusable trigger')
        .parents('.trigger')
        .should('have.attr', 'aria-describedby')
    })
  })

  context('a slot with nothing focusable in it', () => {
    beforeEach(() => {
      cy.visit('/bali/tooltip/keyboard_reach')
    })

    it('makes the wrapper the tab stop and opens on its focus', () => {
      cy.get('.help-tip .trigger').should('have.attr', 'tabindex', '0')

      cy.get('.help-tip .trigger').focus()
      cy.get(balloon).should('be.visible')
        .and('contain', 'Nothing in this slot can take focus')

      cy.get('.help-tip .trigger').blur()
      cy.get(balloon).should('not.exist')
    })
  })

  // An empty tooltip builds no tippy instance, so it must not claim a tab stop either.
  context('an empty tooltip', () => {
    it('stays out of the tab order', () => {
      cy.visit('/bali/tooltip/empty_tooltip')
      cy.get('.trigger').should('not.have.attr', 'tabindex')
    })
  })
})
