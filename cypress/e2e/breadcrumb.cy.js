import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The crumb colours and the scroll start live only in breadcrumb/index.css, which a component
// test cannot see. Before #1343 a linked crumb and the current page computed the same
// base-content, and at 320px the current page showed 26 of its 113px.
describe('breadcrumb', () => {
  const AA = 4.5

  // The trail on its own over base-100, and inside an AppLayout over base-200, where `afal`'s
  // primary is lowest.
  const PREVIEWS = ['/bali/breadcrumb/three_levels', '/bali/app_layout/with_topbar']

  THEMES.forEach((theme) => {
    PREVIEWS.forEach((path) => {
      it(`paints a linked crumb apart from the current page, at AA, on ${theme} (${path})`, () => {
        cy.visit(path)
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get('.breadcrumbs').should(($nav) => {
          expect($nav[0].ownerDocument.getAnimations(), 'colour transitions settled').to.have.length(0)
          const link = $nav[0].querySelector('li a')
          const current = $nav[0].querySelector('[aria-current="page"]')
          const style = el => getComputedStyle(el).color
          expect(style(link), 'a linked crumb is not coloured like the current page').to.not.equal(style(current))
          expect(paintedContrast(link), `${theme}: linked crumb`).to.be.at.least(AA)
        })
      })
    })
  })

  it('keeps the current page in view on a phone, scrolling back to the start', () => {
    cy.viewport(320, 640)
    cy.visit('/bali/breadcrumb/three_levels')

    cy.get('.breadcrumbs').should(($nav) => {
      const nav = $nav[0].getBoundingClientRect()
      const current = $nav[0].querySelector('[aria-current="page"]').getBoundingClientRect()
      expect(current.left, 'current page starts inside the trail').to.be.at.least(nav.left)
      expect(current.right, 'current page ends inside the trail').to.be.at.most(nav.right)
      expect($nav[0].scrollWidth, 'the start of the trail is still there to scroll to')
        .to.be.greaterThan($nav[0].clientWidth)
    })
  })

  it('starts a trail that fits at the start of its box', () => {
    cy.viewport(1280, 800)
    cy.visit('/bali/breadcrumb/three_levels')

    cy.get('.breadcrumbs li a').first().should(($first) => {
      const nav = $first[0].closest('.breadcrumbs').getBoundingClientRect()
      expect($first[0].getBoundingClientRect().left - nav.left, 'first crumb at the left edge')
        .to.be.lessThan(16)
    })
  })
})
