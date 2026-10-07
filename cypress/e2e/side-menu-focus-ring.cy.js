import { paintedContrast } from '../support/painted_contrast'
import { THEMES, token, useTheme } from '../support/themes'

// #1333 — the sidebar's items took the browser's `auto` ring, which does not follow the theme,
// and inside a daisyUI `.menu` panel no ring at all. They ring in the theme's ink now, 2px
// inset, and WCAG 1.4.11 asks 3:1 of it against both what it is drawn over (the item, tinted
// when it is the current or the focused one) and what lies behind.
describe('SideMenu: the focus ring', () => {
  const NON_TEXT = 3
  // Header button (icon-only, found by its name), current item, plain item, group trigger,
  // an item of the group's open `.menu` panel, the module switcher and a rail with `theme:`.
  // The first two load once and switch the page's theme in place; the rail's theme is the
  // preview's `?theme=`, which the server renders, so that one is a visit per theme.
  const IN_PLACE = [
    ['with_bottom_groups?collapsible=true', ['Collapse sidebar', 'Dashboard', 'Projects', 'Configuration', 'Profile']],
    ['with_menu_switcher', ['Back of House']]
  ]
  const RAIL = ['Dashboard', 'Movies', 'Configuration', 'Profile']

  const nameOf = el => (el.getAttribute('aria-label') || el.textContent).trim()

  const stop = (doc, text) =>
    [...doc.querySelectorAll('.side-menu-component :is(a, button, summary, [role="button"])')]
      .find(el => el.getBoundingClientRect().width > 0 && nameOf(el).startsWith(text))

  const expectRings = (theme, preview, stops) => {
    stops.forEach((text) => {
      cy.document().then(doc => stop(doc, text).focus())
      cy.document().should((doc) => {
        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
        const el = doc.activeElement
        const label = `${theme}, ${preview}: ${text}`
        const style = doc.defaultView.getComputedStyle(el)
        expect(nameOf(el), `${label}: focused`).to.match(new RegExp(`^${text}`))
        expect(el.matches(':focus-visible'), `${label}: keyboard focus`).to.equal(true)
        expect(style.outlineStyle, `${label}: ring drawn`).to.equal('solid')
        expect(style.outlineColor, `${label}: in the theme's ink`).to.equal(token(el, 'base-content'))
        expect(paintedContrast(el, { property: 'outlineColor' }), `${label}: over the item`)
          .to.be.at.least(NON_TEXT)
        expect(paintedContrast(el, { over: el.parentElement, property: 'outlineColor' }), `${label}: behind it`)
          .to.be.at.least(NON_TEXT)
      })
    })
  }

  beforeEach(() => cy.viewport(1280, 800))

  IN_PLACE.forEach(([preview, stops]) => {
    it(`rings at 3:1 in the theme's ink on ${preview}, every theme`, () => {
      cy.visit(`/bali/side_menu/${preview}`)

      THEMES.forEach((theme) => {
        useTheme(theme)
        expectRings(theme, preview, stops)
      })
    })
  })

  THEMES.forEach((theme) => {
    it(`rings at 3:1 in the theme's ink on a ${theme} rail`, () => {
      const preview = `dark_chrome?theme=${theme}`
      cy.visit(`/bali/side_menu/${preview}`)
      useTheme(theme)
      expectRings(theme, preview, RAIL)
    })
  })
})
