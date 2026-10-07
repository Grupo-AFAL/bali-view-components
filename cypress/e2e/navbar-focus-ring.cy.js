import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// What sits in the bar rings in the bar's text colour. daisyUI rings a `.btn` in its own colour
// and a `.menu` link not at all: the `btn-neutral` "Sign up" measured 1.26–1.72:1 on a
// transparent bar in the dark themes and 1.00 on an opaque `neutral` bar. WCAG 1.4.11 asks 3:1.
describe('Navbar: the focus ring', () => {
  const NON_TEXT = 3
  const BARS = [
    ['transparent', 'neutral', '&transparency=true'],
    ...['base', 'primary', 'secondary', 'accent', 'neutral'].map(color => [color, color, ''])
  ]

  const open = (color, query, theme) => {
    cy.visit(`/bali/navbar/default?color=${color}${query}`)
    cy.get('nav.navbar').should('have.class', `navbar-${color}`)
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }

  const stop = (nav, text) =>
    [...nav.querySelectorAll('a, [role="button"]')].find(el => el.textContent.trim() === text)

  // The ring is drawn 2px outside the element, over whatever is behind it.
  const expectRing = (el, label) => {
    const style = window.getComputedStyle(el)
    expect(el.matches(':focus-visible'), `${label}: keyboard focus`).to.equal(true)
    expect(style.outlineStyle, `${label}: ring drawn`).to.equal('solid')
    expect(paintedContrast(el, { over: el.parentElement, property: 'outlineColor' }), label)
      .to.be.at.least(NON_TEXT)
  }

  BARS.forEach(([bar, color, query]) => {
    it(`rings at 3:1 on the ${bar} bar, every theme`, () => {
      cy.viewport(1280, 800)
      open(color, query, 'light')

      THEMES.forEach((theme) => {
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
        ;['LOGO', 'Home', 'More', 'Sign up', 'Log in'].forEach((text) => {
          cy.get('nav.navbar').then($nav => stop($nav[0], text).focus())
          cy.document().should((doc) => {
            expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
            expectRing(doc.activeElement, `${theme}, ${bar} bar: ${text}`)
          })
        })
      })
    })
  })

  // The "More" panel is a base-100 surface of its own, and its items are plain `<li><a>`, not
  // menuitems: with the preset's ring "About" measured 1.23:1 on a `primary` bar in `light`.
  it('rings an item of a Dropdown panel in the bar in the panel\'s colour', () => {
    cy.viewport(1280, 800)
    open('primary', '', 'light')

    cy.get('nav.navbar [data-dropdown-target="trigger"]').focus()
      .trigger('keydown', { key: 'Enter', bubbles: true })
    cy.get('nav.navbar').then($nav => stop($nav[0], 'About').focus())
    cy.document().should((doc) => {
      expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
      expect(doc.activeElement.textContent.trim(), 'the open panel took focus').to.equal('About')
      expectRing(doc.activeElement, 'About in the More panel')
    })
  })

  // Below lg the menu is a base-100 panel under the bar, and a filled button in it would
  // otherwise take the ring of a coloured bar: primary-content over base-100.
  it('rings a filled button in the open mobile menu in the menu\'s colour', () => {
    cy.viewport(400, 800)
    open('primary', '', 'afal')
    cy.get('[data-navbar-target="burger"]').click()
    cy.get('[data-navbar-target="menu"]').should('have.css', 'display', 'flex')

    cy.get('nav.navbar').then($nav => stop($nav[0], 'Sign up').focus())
    cy.document().should((doc) => {
      expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
      expectRing(doc.activeElement, 'Sign up in the mobile menu')
    })
  })
})
