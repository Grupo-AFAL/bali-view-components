import { paintedContrast } from '../support/painted_contrast'
import { THEMES, token, useTheme } from '../support/themes'

// The crumb colours and the scroll start live only in breadcrumb/index.css, which a component
// test cannot see. Before #1343 a linked crumb and the current page computed the same
// base-content, and at 320px the current page showed 26 of its 113px.
describe('breadcrumb', () => {
  const AA = 4.5

  // The trail on its own over base-100, and inside an AppLayout over base-200, where `afal`'s
  // primary is lowest. One visit each: the theme switches in place.
  const PREVIEWS = ['/bali/breadcrumb/three_levels', '/bali/app_layout/with_topbar']

  PREVIEWS.forEach((path) => {
    it(`paints a linked crumb apart from the current page, at AA, on every theme (${path})`, () => {
      cy.visit(path)

      THEMES.forEach((theme) => {
        useTheme(theme)

        cy.get('.breadcrumbs').should(($nav) => {
          expect($nav[0].ownerDocument.getAnimations(), `${theme}: colour transitions settled`).to.have.length(0)
          const link = $nav[0].querySelector('li a')
          const current = $nav[0].querySelector('[aria-current="page"]')
          const style = el => getComputedStyle(el).color
          expect(style(current), `${theme}: the current page in base-content`).to.equal(token($nav[0], 'base-content'))
          expect(style(link), `${theme}: a linked crumb is not coloured like the current page`).to.not.equal(style(current))
          expect(paintedContrast(link), `${theme}: linked crumb`).to.be.at.least(AA)
        })
      })
    })
  })

  const currentInView = ($nav) => {
    const nav = $nav[0].getBoundingClientRect()
    const current = $nav[0].querySelector('[aria-current="page"]').getBoundingClientRect()
    expect(current.left, 'current page starts inside the trail').to.be.at.least(nav.left)
    expect(current.right, 'current page ends inside the trail').to.be.at.most(nav.right)
    expect($nav[0].scrollWidth, 'the trail is wider than its box').to.be.greaterThan($nav[0].clientWidth)
    expect($nav[0].ownerDocument.documentElement.scrollWidth, 'the page does not scroll sideways')
      .to.be.at.most(320)
  }

  it('keeps the current page in view on a phone, scrolling back to the start', () => {
    cy.viewport(320, 640)
    cy.visit('/bali/breadcrumb/three_levels')

    cy.get('.breadcrumbs').should(currentInView).then(($nav) => {
      const first = $nav[0].querySelector('li a')
      const left = $nav[0].getBoundingClientRect().left
      expect(first.getBoundingClientRect().left, 'first crumb starts out of view').to.be.lessThan(left)
      $nav[0].scrollLeft = -$nav[0].scrollWidth
      expect(first.getBoundingClientRect().left, 'first crumb reached by scrolling').to.be.at.least(left)
    })
  })

  // The path the apps take: `breadcrumbs:` of a ShowPage inside AppLayout, where the trail only
  // scrolls if an ancestor bounds its width. Two levels are cloned in so that it cannot fit at
  // 320px whatever the seeded title.
  it('keeps the current page in view inside a ShowPage on a phone', () => {
    cy.viewport(320, 640)
    cy.visit(`${new URL(Cypress.config('baseUrl')).origin}/admin/movies/1`)

    cy.get('.breadcrumbs ul').then(($ul) => {
      const list = $ul[0]
      list.insertBefore(list.firstElementChild.cloneNode(true), list.lastElementChild)
      list.insertBefore(list.firstElementChild.cloneNode(true), list.lastElementChild)
    })
    cy.get('.breadcrumbs').should(currentInView)
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
