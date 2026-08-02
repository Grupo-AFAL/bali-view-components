// The keyboard half of the tooltip's default trigger never fired. tippy honours `focus`
// only when the focused element IS the reference, and the reference is the wrapper the
// template puts around the `trigger` slot — no tabindex, so it never took focus. Neither
// end of the slot contract worked: a focusable control inside it could not open the
// balloon, and a slot with nothing focusable in it had no keyboard route at all.
describe('TooltipController', () => {
  const balloon = '[data-tippy-root]'
  // Same list the controller uses to decide whether the slot already brought a tab stop.
  const FOCUSABLE = 'a[href], button, input, select, textarea, summary, [contenteditable], ' +
    '[tabindex]:not([tabindex="-1"])'

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

  // Balloon content that carries no plain text at all — an image, an `<svg>`, a chart — is a
  // supported shape: the template hands tippy markup and `allowHTML` is on. The empty check
  // asked whether there was text, so these tooltips returned before they were built, and
  // `makeTriggerFocusable` never ran either: no balloon and no tab stop, silently (#788).
  context('a balloon that holds markup and no text', () => {
    beforeEach(() => {
      cy.visit('/bali/tooltip/markup_content')
    })

    it('builds the balloon around an image', () => {
      cy.get('.image-balloon .trigger').focus()
      cy.get(`${balloon} .tippy-content img`).should('be.visible')
    })

    it('builds the balloon around an svg', () => {
      cy.get('.sparkline-balloon .trigger').focus()
      cy.get(`${balloon} .tippy-box`).should('be.visible')
      cy.get(`${balloon} .tippy-content svg`).should('exist')
    })

    // The other half of the defect: with no instance built, the wrapper never took
    // `tabindex` either, so the tooltip did not exist for the keyboard any more than for
    // the mouse. Counting the stops pins that it gains exactly one per tooltip.
    it('reaches both balloons with the keyboard, one stop each', () => {
      cy.get('.image-balloon .trigger').should('have.attr', 'tabindex', '0')
      cy.get('.sparkline-balloon .trigger').should('have.attr', 'tabindex', '0')

      cy.get(FOCUSABLE).should('have.length', 2)
      cy.get(FOCUSABLE).each(($el) => {
        cy.wrap($el).should('have.attr', 'data-tooltip-target', 'trigger')
      })
    })
  })

  // An empty tooltip builds no tippy instance, so it must not claim a tab stop either. This
  // is the case the guard exists for and #788 has to leave alone: `with_trigger` with no
  // content block is still nothing to say, and a balloon that never opens must not take a
  // stop. The whitespace the ERB leaves inside the `<template>` is why the check cannot
  // simply count child nodes.
  context('an empty tooltip', () => {
    it('stays out of the tab order and opens nothing', () => {
      cy.visit('/bali/tooltip/empty_tooltip')
      cy.get('.trigger').should('not.have.attr', 'tabindex')

      cy.get('.trigger').trigger('mouseenter')
      cy.get(balloon).should('not.exist')
    })
  })
})
