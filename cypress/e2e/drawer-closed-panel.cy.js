// A closed drawer stays rendered just past the edge of the viewport, so that it can slide
// (drawer/index.css). Rendered is not the same as gone: its controls stayed in the tab order,
// a closed drawer inside an open one slid on screen with it, and on a phone the panel widened
// to the full screen as it began to slide out.
describe('Drawer: the closed panel', () => {
  const panelOf = (dialog) => dialog.querySelector('.drawer-panel')
  const viewportWidth = (dialog) => dialog.ownerDocument.defaultView.innerWidth

  context('out of the tab order', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/skeleton_placeholder')
      cy.get('#details-drawer').should('not.have.class', 'drawer-open')
    })

    it('cannot take the focus while closed', () => {
      cy.get('#details-drawer').should(([dialog]) => {
        const close = dialog.querySelector('.drawer-header button')
        close.focus()

        expect(dialog.ownerDocument.activeElement, 'the focused element').not.to.equal(close)
      })
    })

    it('takes it on opening, and stays painted through the slide-out', () => {
      cy.contains('button', 'Show details').click()
      cy.focused().should('match', '#details-drawer .drawer-header button')

      cy.get('#details-drawer').then(([dialog]) => {
        dialog.querySelector('.drawer-overlay').click()

        expect(getComputedStyle(dialog).visibility, 'visibility as the slide-out starts').to.equal('visible')
      })

      cy.get('#details-drawer').should(([dialog]) => {
        expect(getComputedStyle(dialog).visibility, 'visibility once closed').to.equal('hidden')
      })
      cy.focused().should('contain', 'Show details')
    })
  })

  context('inside an open drawer', () => {
    const expectOffScreen = (dialog) => {
      expect(panelOf(dialog).getAnimations(), 'transitions settled').to.have.length(0)
      expect(panelOf(dialog).getBoundingClientRect().left, 'left edge of the closed panel')
        .to.be.at.least(viewportWidth(dialog))
      expect(getComputedStyle(dialog.querySelector('.drawer-overlay')).display, 'its overlay').to.equal('none')
    }

    beforeEach(() => {
      cy.visit('/bali/drawer/nested')
      cy.get('#outer-drawer').should('have.class', 'drawer-open')
    })

    it('stays off screen until its own trigger opens it', () => {
      cy.get('#inner-drawer').should(([dialog]) => expectOffScreen(dialog))

      cy.contains('button', 'Show history').click()
      cy.get('#inner-drawer').should(([dialog]) => {
        expect(panelOf(dialog).getAnimations(), 'transitions settled').to.have.length(0)
        expect(panelOf(dialog).getBoundingClientRect().right, 'right edge of the open panel')
          .to.be.closeTo(viewportWidth(dialog), 1)
      })

      cy.focused().type('{esc}')
      cy.get('#inner-drawer').should(([dialog]) => expectOffScreen(dialog))
      cy.get('#outer-drawer').should('have.class', 'drawer-open')
    })

    // The closed drawer's ✕ comes last in the outer panel. It cannot take the focus, so as
    // the edge of the outer drawer's Tab trap it let Tab out of the overlay.
    it('leaves the Tab cycle of the open drawer to its own controls', () => {
      const outerClose = '#outer-drawer > .drawer-panel > .drawer-header button'
      const trigger = '#outer-drawer button[data-drawer-id="inner-drawer"]'
      const expectFocusOn = (selector) => cy.document().should(doc => {
        expect(doc.activeElement, 'the focused element').to.equal(doc.querySelector(selector))
      })

      cy.get(outerClose).focus()
      cy.press(Cypress.Keyboard.Keys.TAB)
      expectFocusOn(trigger)
      cy.press(Cypress.Keyboard.Keys.TAB)
      expectFocusOn(outerClose)

      // `cy.press` takes no modifiers; the wrap backwards is the trap's own handler.
      cy.focused().trigger('keydown', { key: 'Tab', shiftKey: true })
      expectFocusOn(trigger)
    })
  })

  context('on a phone', () => {
    beforeEach(() => {
      cy.viewport(390, 844)
      cy.visit('/bali/drawer/default')
      cy.get('dialog.drawer-component').should('have.class', 'drawer-open')
    })

    it('keeps its width as it slides out', () => {
      cy.get('dialog.drawer-component').should(([dialog]) => {
        expect(panelOf(dialog).getAnimations(), 'transitions settled').to.have.length(0)
      })

      cy.get('dialog.drawer-component').then(([dialog]) => {
        const opened = panelOf(dialog).getBoundingClientRect().width
        expect(opened, 'width of the open panel').to.be.below(viewportWidth(dialog))

        dialog.querySelector('.drawer-overlay').click()

        expect(panelOf(dialog).getBoundingClientRect().width, 'width as the slide-out starts').to.equal(opened)
      })
    })
  })
})
