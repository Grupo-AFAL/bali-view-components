import { paintedContrast } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The burger and a `variant: :ghost` brand are daisyUI ghost buttons, and daisyUI paints one at
// rest with base-content whatever bar it sits on: the burger on a `neutral` navbar measured
// 1.00:1 on `afal` and `costa-norte`, and 1.69 on `primary` in `costa-norte` (#1257). It has to
// read like the bar's own text. The burger is an icon, so WCAG 1.4.11 asks 3:1.
describe('Navbar: ghost buttons on a coloured bar', () => {
  const NON_TEXT = 3
  const COLORS = ['base', 'primary', 'secondary', 'accent', 'neutral']

  // The burger only shows below `lg`.
  beforeEach(() => cy.viewport(400, 800))

  const open = (color, theme) => {
    cy.visit(`/bali/navbar/default?color=${color}`)
    // Proves the preview honoured `?color=`: one it ignored renders `navbar-base`.
    cy.get('nav.navbar').should('have.class', `navbar-${color}`)
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }

  THEMES.forEach((theme) => {
    COLORS.forEach((color) => {
      it(`the burger reads at 3:1 on the ${color} navbar, ${theme} theme`, () => {
        open(color, theme)

        cy.get('nav.navbar').should(($nav) => {
          expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
          const burger = $nav[0].querySelector('[data-navbar-target="burger"]')
          expect(burger.offsetWidth, 'the burger shows at this width').to.be.greaterThan(0)
          expect(burger.matches(':hover'), 'measured at rest').to.equal(false)
          expect(paintedContrast(burger.querySelector('svg')), `${theme}: ${color} navbar`).to.be.at.least(NON_TEXT)
        })
      })

      it(`the ghost brand paints the text colour of the ${color} navbar, ${theme} theme`, () => {
        open(color, theme)

        cy.get('nav.navbar').should(($nav) => {
          expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
          const brand = $nav[0].querySelector('.navbar-brand .btn-ghost')
          expect(brand.matches(':hover'), 'measured at rest').to.equal(false)
          const { color: ink } = window.getComputedStyle(brand)
          expect(ink, `${theme}: ${color} navbar`).to.equal(window.getComputedStyle($nav[0]).color)
        })
      })
    })
  })

  // Why `currentColor` and not the preset's `-content`: the menu that opens under the burger is
  // `bg-base-100 text-base-content`, inside the bar.
  COLORS.forEach((color) => {
    it(`a ghost button in the open menu of the ${color} navbar paints the menu's text colour`, () => {
      open(color, 'light')
      cy.get('[data-navbar-target="burger"]').click()

      cy.get('[data-navbar-target="menu"]').should(($menu) => {
        expect($menu.css('display'), 'the menu is open').to.equal('flex')
        expect($menu[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
        const ghost = $menu[0].querySelector('.btn-ghost')
        expect(window.getComputedStyle(ghost).color).to.equal(window.getComputedStyle($menu[0]).color)
      })
    })
  })

  // The value keeps daisyUI's chain and only drops its base-content step.
  it('a ghost button with a colour of its own keeps it inside the bar', () => {
    open('neutral', 'light')
    cy.get('nav.navbar').then(($nav) => {
      const markup = '<button type="button" class="btn btn-ghost btn-error">Sign out</button>'
      $nav[0].querySelector('.navbar-brand').insertAdjacentHTML('beforeend', markup)
      $nav[0].ownerDocument.body.insertAdjacentHTML('beforeend', markup)
    })

    cy.get('.btn-ghost.btn-error').should(($buttons) => {
      expect($buttons, 'one in the bar, one on the page').to.have.length(2)
      const [inBar, onPage] = $buttons.toArray().map(b => window.getComputedStyle(b).color)
      expect(inBar, 'the error colour, not the text of the bar').to.equal(onPage)
    })
  })
})
