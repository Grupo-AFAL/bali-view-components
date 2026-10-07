import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'
import { paintedLuminance as luminance } from '../support/painted_contrast'

// A rail with its own `theme:` is chrome next to the page, and its hover, borders and the
// switcher's panel are meant to sit a step ABOVE the rail. daisyUI's `dark` and Bali's dark
// themes step base-200/300 DOWN from base-100 — the page sits under its cards — so inside the
// rail that panel measured 1.05–1.07:1 against the rail and its border went darker still.
describe('SideMenu chrome surfaces', () => {
  afterEach(() => { unhover() })

  const DARK_THEMES = ['dark', 'afal-dark', 'costa-norte-dark']

  // The rail's theme is the preview's `?theme=`, rendered by the server: one visit per theme.
  DARK_THEMES.forEach((theme) => {
    it(`lifts the panel and the borders above a ${theme} rail, and shows the hovered item inside the panel`, () => {
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

      // The bottom group's items are `.menu-item`s, whose hover was base-200 — the panel's own
      // colour inside a themed rail, so the hovered item measured 1.00:1 against it.
      cy.get('.side-menu-component').contains('Configuration').click()
      cy.get('.side-menu-bottom-section .dropdown-content .menu-item').first().then(hover)

      cy.get('.side-menu-bottom-section .dropdown-content').should(($panel) => {
        const doc = $panel[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const item = $panel[0].querySelector('.menu-item:hover')

        expect(item, 'an item under the pointer').to.not.equal(null)
        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
        const panelColour = style($panel[0]).backgroundColor
        const panel = luminance(doc, panelColour)
        const hovered = luminance(doc, panelColour, style(item).backgroundColor)
        expect((Math.max(hovered, panel) + 0.05) / (Math.min(hovered, panel) + 0.05), `${theme}: hovered item against the panel`)
          .to.be.at.least(1.15)
      })
    })
  })

  // Without a `theme:` the rail is base-100 like its panels, and on a dark page the shadow
  // does not show: same edge as Bali::Dropdown, same border.
  it('draws the edge of a panel opened from an unthemed rail on every dark page', () => {
    cy.visit('/bali/side_menu/with_bottom_groups')
    DARK_THEMES.forEach((theme) => {
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.side-menu-component:not([data-theme]) .dropdown-content').first().should(($panel) => {
        const doc = $panel[0].ownerDocument
        const style = (el) => doc.defaultView.getComputedStyle(el)
        const railColour = style($panel[0].closest('.side-menu-component')).backgroundColor
        const rail = luminance(doc, railColour)
        const edge = luminance(doc, railColour, style($panel[0]).borderTopColor)

        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
        expect(parseFloat(style($panel[0]).borderTopWidth), 'border width').to.be.at.least(1)
        expect((Math.max(edge, rail) + 0.05) / (Math.min(edge, rail) + 0.05), `${theme}: edge against the rail`)
          .to.be.above(1.2)
      })
    })
  })

  // base-200 steps down on the dark themes, so a hovered item painted darker than its rail,
  // 1.05:1, and an inline rail's base-300 1.04–1.09. The ink at 8% lifts it on a dark rail
  // and darkens it on a light one: 1.20 and 1.16 on afal-dark and afal. An inline rail is
  // transparent, so the hover lands on whatever the host painted under it.
  const opaqueGround = (el) => {
    const doc = el.ownerDocument
    const ctx = Object.assign(doc.createElement('canvas'), { width: 1, height: 1 })
      .getContext('2d', { willReadFrequently: true })
    for (let node = el; node; node = node.parentElement) {
      const colour = doc.defaultView.getComputedStyle(node).backgroundColor
      ctx.clearRect(0, 0, 1, 1)
      ctx.fillStyle = colour
      ctx.fillRect(0, 0, 1, 1)
      if (ctx.getImageData(0, 0, 1, 1).data[3] === 255) return colour
    }
    return 'white'
  }

  ;[['fixed', '/bali/side_menu/default'], ['inline', '/bali/side_menu/with_icons']].forEach(([kind, url]) => {
    it(`shows the hovered item of an unthemed ${kind} rail on every theme`, () => {
      cy.viewport(1280, 800)
      cy.visit(url)
      cy.get('.side-menu-component a.menu-item:not(.active):visible').eq(1).then(hover)
      THEMES.forEach((theme) => {
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get('.side-menu-component a.menu-item:hover').should(($item) => {
          const doc = $item[0].ownerDocument
          const ground = opaqueGround($item[0].parentElement)
          const under = luminance(doc, ground)
          const hovered = luminance(doc, ground, doc.defaultView.getComputedStyle($item[0]).backgroundColor)

          expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
          expect((Math.max(hovered, under) + 0.05) / (Math.min(hovered, under) + 0.05), `${theme}: hovered item against what is under it`)
            .to.be.at.least(1.15)
        })
      })
    })
  })
})
