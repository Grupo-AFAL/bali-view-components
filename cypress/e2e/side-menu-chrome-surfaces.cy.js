import { pointAt } from '../support/tap'
import { THEMES } from '../support/themes'
import { paintedLuminance as luminance } from '../support/painted_contrast'

// A rail with its own `theme:` is chrome next to the page, and its hover, borders and the
// switcher's panel are meant to sit a step ABOVE the rail. daisyUI's `dark` and Bali's dark
// themes step base-200/300 DOWN from base-100 — the page sits under its cards — so inside the
// rail that panel measured 1.05–1.07:1 against the rail and its border went darker still.
describe('SideMenu chrome surfaces', () => {
  ;['dark', 'afal-dark', 'costa-norte-dark'].forEach((theme) => {
    it(`lifts the panel and the borders above a ${theme} rail`, () => {
      cy.visit(`/bali/side_menu/dark_chrome?theme=${theme}`)

      cy.get(`.side-menu-component[data-theme="${theme}"]`).should(($rail) => {
        const doc = $rail[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const rail = luminance(doc, style($rail[0]).backgroundColor)
        const panel = luminance(doc, style($rail[0].querySelector('.dropdown-content')).backgroundColor)
        const border = luminance(doc, style($rail[0].querySelector('.side-menu-expanded')).borderBottomColor)

        expect(panel, `${theme}: panel above the rail`).to.be.above(rail)
        expect(border, `${theme}: border above the panel`).to.be.above(panel)
      })
    })

    // The bottom group's items are `.menu-item`s, whose hover was base-200 — the panel's own
    // colour inside a themed rail, so the hovered item measured 1.00:1 against it.
    it(`shows the hovered item inside the panel of a ${theme} rail`, () => {
      cy.visit(`/bali/side_menu/dark_chrome?theme=${theme}`)
      cy.get('.side-menu-component').contains('Configuration').click()
      cy.get('.side-menu-bottom-section .dropdown-content .menu-item').first().then(pointAt)

      cy.get('.side-menu-bottom-section .dropdown-content').should(($panel) => {
        const doc = $panel[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const item = $panel[0].querySelector('.menu-item:hover')

        expect(item, 'an item under the pointer').to.not.equal(null)
        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
        expect(luminance(doc, style(item).backgroundColor), `${theme}: hovered item above the panel`)
          .to.be.above(luminance(doc, style($panel[0]).backgroundColor))
      })
    })
  })

  // Without a `theme:` the rail is base-100 like its panels, and on a dark page the shadow
  // does not show: same edge as Bali::Dropdown, same border.
  ;['dark', 'afal-dark', 'costa-norte-dark'].forEach((theme) => {
    it(`draws the edge of a panel opened from an unthemed rail on a ${theme} page`, () => {
      cy.visit('/bali/side_menu/with_bottom_groups')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.side-menu-component:not([data-theme]) .dropdown-content').first().should(($panel) => {
        const doc = $panel[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const railColour = style($panel[0].closest('.side-menu-component')).backgroundColor
        const rail = luminance(doc, railColour)
        const edge = luminance(doc, railColour, style($panel[0]).borderTopColor)

        expect(parseFloat(style($panel[0]).borderTopWidth), 'border width').to.be.at.least(1)
        expect((Math.max(edge, rail) + 0.05) / (Math.min(edge, rail) + 0.05), `${theme}: edge against the rail`)
          .to.be.above(1.2)
      })
    })
  })

  // base-200 steps down on the dark themes, so a hovered item painted darker than its rail,
  // 1.05:1. The ink at 8% lifts it on a dark rail and darkens it on a light one: 1.20 and
  // 1.16 on afal-dark and afal, the proposal Federico chose.
  THEMES.forEach((theme) => {
    it(`shows the hovered item of an unthemed rail on the ${theme} theme`, () => {
      cy.viewport(1280, 800)
      cy.visit('/bali/side_menu/default')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
      cy.get('.side-menu-component a.menu-item:not(.active):visible').eq(1).then(pointAt)

      cy.get('.side-menu-component a.menu-item:hover').should(($item) => {
        const doc = $item[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const railColour = style($item[0].closest('.side-menu-component')).backgroundColor
        const rail = luminance(doc, railColour)
        const hovered = luminance(doc, railColour, style($item[0]).backgroundColor)

        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
        expect((Math.max(hovered, rail) + 0.05) / (Math.min(hovered, rail) + 0.05), `${theme}: hovered item against the rail`)
          .to.be.at.least(1.15)
      })
    })
  })
})
