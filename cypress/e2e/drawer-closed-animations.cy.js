// The contrast guards under AppLayout wait for `doc.getAnimations()` to empty (testing-traps.md);
// this spec keeps a closed drawer from holding it open.
describe('Drawer: what animates while it is closed', () => {
  const skeletons = doc => doc.querySelectorAll('#main-drawer .skeleton')
  const skeletonAnimations = doc =>
    doc.getAnimations().filter(a => a.animationName === 'skeleton' && a.playState === 'running')
  const animationNames = doc => doc.getAnimations().map(a => a.animationName || a.transitionProperty)
  const expectEverySkeletonAnimating = (doc, where) => {
    const count = skeletons(doc).length
    expect(count, `skeletons in ${where}`).to.be.greaterThan(0)
    expect(skeletonAnimations(doc), `skeleton animations in ${where}`).to.have.length(count)
  }

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
    // Fails if the layout stops rendering the skeleton, so the zero below means something.
    cy.get('#main-drawer .skeleton').should('have.length.greaterThan', 0)
    cy.get('#main-drawer').should('not.have.class', 'drawer-open').and('not.have.attr', 'open')
  })

  it('leaves a page with a closed drawer without animations', () => {
    cy.document().should(doc => {
      expect(animationNames(doc), 'animations on the page').to.have.length(0)
    })
  })

  it('animates the skeleton once the drawer opens', () => {
    openDrawer()

    cy.document().should(doc => expectEverySkeletonAnimating(doc, 'the open drawer'))
  })

  it('stops the skeleton again once the drawer closes', () => {
    openDrawer()
    cy.document().should(doc => expectEverySkeletonAnimating(doc, 'the open drawer'))

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
      expectEverySkeletonAnimating(doc, 'the panel')
    })
  })
})
