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

  // tippy MOVES what it is handed, so passing it `template.content` emptied the `<template>`
  // on the first connect. Nothing noticed while the node stayed put; move the same node in
  // the DOM and the second `connect` re-read an empty template, tripped the empty guard, and
  // rebuilt neither the balloon nor the tab stop (#803). Anything that relocates the element
  // instead of replacing it with fresh markup lands here — a reordered list, a node pulled
  // out and put back, a morph that keeps the element and reconnects its controllers.
  context('a tooltip whose node is moved in the DOM', () => {
    // The invariant the fix rests on, and the cheapest thing to assert: after connecting,
    // the `<template>` still holds what the server rendered.
    it('leaves the template populated after connecting', () => {
      cy.visit('/bali/tooltip/help_tip')
      cy.get('.help-tip .trigger').should('have.attr', 'tabindex', '0')

      cy.get('.help-tip template[data-tooltip-target="content"]').should($tpl => {
        expect($tpl[0].content.textContent).to.contain('this is the help tip content')
      })
    })

    // The issue's exact scenario: take the element out and put it back, which is a real
    // Stimulus disconnect + connect over the same node.
    it('rebuilds the balloon after the element is removed and re-inserted', () => {
      cy.visit('/bali/tooltip/help_tip')
      cy.get('.help-tip .trigger').should('have.attr', 'tabindex', '0')

      cy.get('.help-tip').then($el => {
        const el = $el[0]
        const parent = el.parentNode
        const next = el.nextSibling
        parent.removeChild(el)
        // Stimulus disconnects on the next microtask; re-inserting in the same tick would
        // not exercise a reconnect at all.
        cy.wrap(null).wait(100).then(() => parent.insertBefore(el, next))
      })

      // The tab stop is `makeTriggerFocusable` having run again, so it pins the whole of
      // `connect` re-running, not just tippy.
      cy.get('.help-tip .trigger').should('have.attr', 'tabindex', '0')

      cy.get('.help-tip .trigger').focus()
      cy.get(balloon).should('be.visible')
        .and('contain', 'this is the help tip content')
    })

    // The same defect through the door an app actually walks in: reordering siblings moves
    // the nodes rather than re-rendering them, and Stimulus does treat that as a reconnect —
    // measured, reversing a row of three controllers reports 3 disconnects and 3 connects
    // even though every move happens in one tick.
    it('rebuilds every balloon after the tooltips are reordered', () => {
      cy.visit('/bali/tooltip/all_placements')
      cy.get('.tooltip-component').should('have.length', 4)

      // tippy numbers its instances, so the id is what tells a rebuilt balloon apart from
      // the one the first connect left behind.
      const idsBefore = []
      cy.get('.tooltip-component .trigger').each($t => idsBefore.push($t[0]._tippy.id))

      cy.get('.tooltip-component').then($els => {
        const parent = $els[0].parentNode
        // Reverse the row: every tooltip is moved, so every controller reconnects.
        Cypress.$($els).get().reverse().forEach(el => parent.appendChild(el))
      })

      // The reconnect settles asynchronously — Stimulus dispatches off a MutationObserver
      // and `connect` awaits the tippy import. Asserting straight after the reorder reads
      // the instances the first connect built and passes against the broken code too, so
      // wait until every trigger carries an instance that did not exist before the move.
      cy.get('.tooltip-component .trigger').should($ts => {
        const idsAfter = Cypress.$($ts).get().map(t => t._tippy?.id)
        expect(idsAfter, 'every balloon rebuilt').to.have.length(4)
        idsAfter.forEach(id => {
          expect(id, 'a new tippy instance').to.be.a('number')
          expect(idsBefore, 'not the instance from the first connect').to.not.include(id)
        })
      })

      cy.get('.tooltip-component').each($el => {
        cy.wrap($el).find('.trigger').focus()
        cy.get(balloon).should('be.visible')
        cy.wrap($el).find('.trigger').blur()
      })
    })
  })
})
