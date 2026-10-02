// A closed drawer stays rendered, off screen, so it can slide back in, and daisyUI animates
// `.skeleton` forever: AppLayout's closed drawer kept 15 `skeleton` animations on
// `document.getAnimations()` (#1273), and the contrast guards under AppLayout wait for that list
// to empty.
describe('Drawer: what animates while it is closed', () => {
  const skeletonAnimations = doc =>
    doc.getAnimations().filter(a => a.animationName === 'skeleton' && a.playState === 'running')

  beforeEach(() => {
    cy.visit('/bali/app_layout/default')
    // Fails if the layout stops rendering the skeleton, so the zero below means something.
    cy.get('#main-drawer .skeleton').should('have.length', 15)
    cy.get('#main-drawer').should('not.have.attr', 'open')
  })

  it('leaves a page with a closed drawer without animations', () => {
    cy.document().should(doc => {
      expect(doc.getAnimations().map(a => a.animationName || a.transitionProperty), 'animations on the page')
        .to.have.length(0)
    })
  })

  it('animates the skeleton once the drawer opens', () => {
    cy.document().then(doc => {
      doc.dispatchEvent(new CustomEvent('bali:drawer:open', {
        detail: { id: 'main-drawer', content: null, options: {} }
      }))
    })

    cy.get('#main-drawer').should('have.attr', 'open')
    cy.document().should(doc => {
      expect(skeletonAnimations(doc), 'skeleton animations in the open drawer').to.have.length(15)
    })
  })

  // The panel is on screen when the root carries `drawer-open`, which an `active:` drawer has
  // from the server, before its controller connects and calls `showModal()`. Keyed on `[open]`
  // instead, that panel would show a skeleton frozen until then.
  it('animates the skeleton of a panel marked open before the dialog is', () => {
    cy.get('#main-drawer').then($drawer => $drawer[0].classList.add('drawer-open'))

    cy.document().should(doc => {
      expect(doc.getElementById('main-drawer').open, 'the dialog itself').to.equal(false)
      expect(skeletonAnimations(doc), 'skeleton animations in the panel').to.have.length(15)
    })
  })
})
