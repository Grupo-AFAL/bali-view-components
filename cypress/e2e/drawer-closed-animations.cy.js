// The contrast guards under AppLayout wait for `doc.getAnimations()` to empty (testing-traps.md);
// this spec keeps a closed drawer from holding it open.
describe('Drawer: what animates while it is closed', () => {
  const animationNames = doc => doc.getAnimations().map(a => a.animationName || a.transitionProperty)
  const expectEverySkeletonAnimating = (doc, drawer, where) => {
    const count = doc.querySelectorAll(`${drawer} .skeleton`).length
    const running = doc.getAnimations().filter(a =>
      a.animationName === 'skeleton' && a.playState === 'running' && a.effect?.target?.closest(drawer)
    )
    expect(count, `skeletons in ${where}`).to.be.greaterThan(0)
    expect(running, `skeleton animations in ${where}`).to.have.length(count)
  }

  // Fails if the page stops rendering the skeleton, so a zero means something.
  const expectClosedWithSkeleton = drawer => {
    cy.get(`${drawer} .skeleton`).should('have.length.greaterThan', 0)
    cy.get(drawer).should('not.have.class', 'drawer-open').and('not.have.attr', 'open')
  }

  context('AppLayout', () => {
    const openDrawer = () => {
      cy.document().then(doc => {
        doc.dispatchEvent(new CustomEvent('bali:drawer:open', {
          detail: { id: 'main-drawer', content: null, options: {} }
        }))
      })
      cy.get('#main-drawer').should('have.attr', 'open')
    }

    beforeEach(() => {
      cy.visit('/bali/app_layout/default')
      expectClosedWithSkeleton('#main-drawer')
    })

    it('leaves a page with a closed drawer without animations', () => {
      cy.document().should(doc => {
        expect(animationNames(doc), 'animations on the page').to.have.length(0)
      })
    })

    it('animates the skeleton once the drawer opens', () => {
      openDrawer()

      cy.document().should(doc => expectEverySkeletonAnimating(doc, '#main-drawer', 'the open drawer'))
    })

    it('stops the skeleton again once the drawer closes', () => {
      openDrawer()
      cy.document().should(doc => expectEverySkeletonAnimating(doc, '#main-drawer', 'the open drawer'))

      cy.focused().type('{esc}')
      cy.get('#main-drawer').should('not.have.attr', 'open')

      cy.document().should(doc => {
        expect(animationNames(doc), 'animations on the page after closing').to.have.length(0)
      })
    })

    // An `active:` drawer has `drawer-open` from the server, on screen before its controller
    // connects and calls `showModal()`. Keyed on `[open]`, that panel would show a frozen skeleton.
    it('animates the skeleton of a panel marked open before the dialog is', () => {
      cy.get('#main-drawer').then($drawer => $drawer[0].classList.add('drawer-open'))

      cy.document().should(doc => {
        expect(doc.getElementById('main-drawer').open, 'the dialog itself').to.equal(false)
        expectEverySkeletonAnimating(doc, '#main-drawer', 'the panel')
      })
    })
  })

  it('keeps a drawer of its own still until its trigger opens it', () => {
    cy.visit('/bali/drawer/skeleton_placeholder')
    expectClosedWithSkeleton('#details-drawer')

    cy.document().should(doc => {
      expect(animationNames(doc), 'animations on the page').to.have.length(0)
    })

    cy.contains('button', 'Show details').click()
    cy.get('#details-drawer').should('have.attr', 'open')

    cy.document().should(doc => expectEverySkeletonAnimating(doc, '#details-drawer', 'the open drawer'))
  })
})
