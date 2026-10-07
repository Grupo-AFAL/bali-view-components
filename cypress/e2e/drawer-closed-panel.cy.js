// A closed drawer stays rendered just past the edge of the viewport, so that it can slide
// (drawer/index.css). Rendered is not the same as gone: its controls stayed in the tab order,
// a closed drawer inside an open one slid on screen with it, and on a phone the panel widened
// to the full screen as it began to slide out, and its overlay vanished before it had.
describe('Drawer: the closed panel', () => {
  const panelOf = (dialog) => dialog.querySelector('.drawer-panel')
  const viewportWidth = (dialog) => dialog.ownerDocument.defaultView.innerWidth

  context('out of the tab order', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/skeleton_placeholder')
      cy.get('#details-drawer').should('not.have.class', 'drawer-open')
    })

    // `visibility: hidden` on the closed drawer was undone by a descendant that sets
    // `visibility: visible` (a `.visible`, or daisyUI's open collapse where the browser has no
    // `content-visibility`); nothing inside undoes `inert`. Each control is tried with
    // `focus()`, not Tab: the ✕ comes first in the tab order, and would fail the test before
    // the probe was ever reached.
    it('cannot take the focus while closed, not even a descendant that sets visibility: visible', () => {
      cy.get('#details-drawer .drawer-inner').then(([content]) => {
        content.insertAdjacentHTML('beforeend', '<div class="visible"><button id="visible-probe">Probe</button></div>')
      })

      cy.get('#details-drawer').should(([dialog]) => {
        ['#visible-probe', '.drawer-header button'].forEach((selector) => {
          const control = dialog.querySelector(selector)
          control.focus()

          expect(dialog.ownerDocument.activeElement, `the focused element after focusing ${selector}`).not.to.equal(control)
        })
      })
    })

    it('takes it on opening, and gives it back once closed', () => {
      cy.contains('button', 'Show details').click()
      cy.focused().should('match', '#details-drawer .drawer-header button')

      cy.get('#details-drawer').then(([dialog]) => dialog.querySelector('.drawer-overlay').click())

      cy.get('#details-drawer').should(([dialog]) => {
        expect(dialog.inert, 'inert once closed').to.equal(true)
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

  context('below 768px', () => {
    // The panel takes 85% of the screen, but never more than its size allows: a second
    // `max-w-` used to replace that cap, and a `sm` drawer measured 544px at 640.
    [
      { size: 'sm', width: 384 },
      { size: 'md', width: 512 },
      { size: 'full', width: 544 }
    ].forEach(({ size, width }) => {
      it(`keeps the cap of its size, under 85% of the screen: ${size}`, () => {
        cy.viewport(640, 844)
        cy.visit(`/bali/drawer/sizes?size=${size}`)

        cy.get('dialog.drawer-component').should(([dialog]) => {
          expect(panelOf(dialog).getAnimations(), 'transitions settled').to.have.length(0)
          expect(panelOf(dialog).getBoundingClientRect().width, 'width of the open panel at 640px').to.be.closeTo(width, 1)
        })
      })
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

    // Paused halfway through the slide-out: an overlay that vanished on close reads `none`
    // there, while the panel is still half on screen. Still painted, it must not take a click:
    // in Chromium `inert` and the `display` transition each keep it out of hit testing alone.
    it('fades its overlay out with the slide-out', () => {
      cy.get('dialog.drawer-component').should(([dialog]) => {
        expect(dialog.getAnimations({ subtree: true }), 'transitions settled').to.have.length(0)
      })

      cy.get('dialog.drawer-component').then(([dialog]) => {
        const overlay = dialog.querySelector('.drawer-overlay')
        overlay.click()

        const slide = panelOf(dialog).getAnimations()
        expect(slide, 'the slide-out is running').to.have.length.greaterThan(0)
        const transitions = dialog.getAnimations({ subtree: true })
        transitions.forEach((a) => {
          a.pause()
          a.currentTime = slide[0].effect.getComputedTiming().duration / 2
        })
        const halfway = getComputedStyle(overlay)
        expect(halfway.display, 'overlay halfway through the slide-out').to.equal('block')
        expect(Number(halfway.opacity), 'its opacity').to.be.above(0).and.below(1)
        expect(dialog.ownerDocument.elementFromPoint(5, 5), 'what a click on the fading overlay hits').not.to.equal(overlay)
        transitions.forEach((a) => a.play())
      })

      cy.get('dialog.drawer-component').should(([dialog]) => {
        expect(dialog.getAnimations({ subtree: true }), 'transitions settled').to.have.length(0)
        expect(getComputedStyle(dialog.querySelector('.drawer-overlay')).display, 'overlay once closed').to.equal('none')
      })
    })
  })
})
