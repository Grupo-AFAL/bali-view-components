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

  // How far index.css fades each edge, read from the computed mask the breadcrumb controller's
  // attributes select. The controller follows a scroll on its `scroll` event, so readings retry.
  const fades = (nav) => {
    const mask = getComputedStyle(nav).maskImage
    if (mask === 'none') return { start: 0, end: 0 }
    const [, start, end] = mask.match(/rgb\(0, 0, 0\) ([\d.]+)px, rgb\(0, 0, 0\) (?:calc\(100% - ([\d.]+)px\)|100%)/)
    return { start: Number(start), end: Number(end || 0) }
  }
  const scrollToStart = (nav, fraction) => { nav.scrollLeft = -(nav.scrollWidth - nav.clientWidth) * fraction }

  it('fades only the edges where the trail is cut, without an animation', () => {
    cy.viewport(320, 640)
    cy.visit('/bali/breadcrumb/three_levels')

    cy.get('.breadcrumbs').should(($nav) => {
      expect($nav[0].scrollWidth - $nav[0].clientWidth, 'the trail scrolls').to.be.greaterThan(24)
      expect(fades($nav[0]), 'at load, the start is cut').to.deep.equal({ start: 24, end: 0 })
      expect($nav[0].ownerDocument.getAnimations(), 'nothing animates').to.have.length(0)
    }).then(($nav) => scrollToStart($nav[0], 0.5))
    cy.get('.breadcrumbs').should(($nav) => {
      expect(fades($nav[0]), 'halfway, both edges are cut').to.deep.equal({ start: 24, end: 24 })
    }).then(($nav) => scrollToStart($nav[0], 1))
    cy.get('.breadcrumbs').should(($nav) => {
      expect(fades($nav[0]), 'at the start, only the end is cut').to.deep.equal({ start: 0, end: 24 })
    })
  })

  it('fades a trail that fits once it grows past its box', () => {
    cy.viewport(1280, 800)
    cy.visit('/bali/breadcrumb/three_levels')

    // The controller's first reading lands on a frame after it connects. Grown before that, the
    // list would be caught by that reading whether or not the observer watches it.
    const twoFramesLater = (nav) => new Cypress.Promise((resolve) => {
      const win = nav.ownerDocument.defaultView
      win.requestAnimationFrame(() => win.requestAnimationFrame(() => resolve(nav)))
    })

    cy.get('.breadcrumbs').should(($nav) => {
      expect(getComputedStyle($nav[0]).maskImage, 'a trail that fits has no mask').to.equal('none')
    }).then(($nav) => twoFramesLater($nav[0])).then(($nav) => {
      const nav = $nav[0]
      const list = nav.querySelector('ul')
      while (nav.scrollWidth <= nav.clientWidth) {
        list.insertBefore(list.firstElementChild.cloneNode(true), list.lastElementChild)
      }
    })
    cy.get('.breadcrumbs').should(($nav) => {
      expect(fades($nav[0]), 'cut once it grows').to.deep.equal({ start: 24, end: 0 })
    })
  })

  it('drops the fade when the trail comes to fit', () => {
    cy.viewport(320, 640)
    cy.visit('/bali/breadcrumb/three_levels')
    cy.get('.breadcrumbs').should(($nav) => {
      expect(fades($nav[0]), 'cut at 320px').to.deep.equal({ start: 24, end: 0 })
    })

    cy.viewport(1280, 800)
    cy.get('.breadcrumbs').should(($nav) => {
      expect($nav[0].scrollWidth, 'the trail fits').to.equal($nav[0].clientWidth)
      expect(getComputedStyle($nav[0]).maskImage, 'no mask once it fits').to.equal('none')
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
