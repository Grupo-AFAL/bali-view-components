import { paintedContrast } from '../support/painted_contrast'
import { THEMES, useTheme } from '../support/themes'

// The burger and a `variant: :ghost` brand are daisyUI ghost buttons, and daisyUI paints one at
// rest with base-content whatever bar it sits on: the burger on a `neutral` navbar measured
// 1.00:1 on `afal` and `costa-norte`, and 1.69 on `primary` in `costa-norte` (#1257). It has to
// read like the bar's own text. The burger is an icon, so WCAG 1.4.11 asks 3:1.
describe('Navbar: ghost buttons on a coloured bar', () => {
  const NON_TEXT = 3
  const COLORS = ['base', 'primary', 'secondary', 'accent', 'neutral']

  // The burger only shows below `lg`.
  beforeEach(() => cy.viewport(400, 800))

  const open = (color, query = '', preview = 'default') => {
    cy.visit(`/bali/navbar/${preview}?color=${color}${query}`)
    // Proves the preview honoured `?color=`: one it ignored renders `navbar-base`.
    cy.get('nav.navbar').should('have.class', `navbar-${color}`)
  }

  COLORS.forEach((color) => {
    it(`the burger reads at 3:1 and the ghost brand paints the text colour of the ${color} navbar, every theme`, () => {
      open(color)

      THEMES.forEach((theme) => {
        useTheme(theme)
        cy.get('nav.navbar').should(($nav) => {
          expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
          const burger = $nav[0].querySelector('[data-navbar-target="burger"]')
          expect(burger.offsetWidth, 'the burger shows at this width').to.be.greaterThan(0)
          expect(burger.matches(':hover'), 'measured at rest').to.equal(false)
          expect(paintedContrast(burger.querySelector('svg')), `${theme}: ${color} navbar`).to.be.at.least(NON_TEXT)

          const brand = $nav[0].querySelector('.navbar-brand .btn-ghost')
          expect(brand.matches(':hover'), 'measured at rest').to.equal(false)
          const { color: ink } = window.getComputedStyle(brand)
          expect(ink, `${theme}: ${color} navbar`).to.equal(window.getComputedStyle($nav[0]).color)
        })
      })
    })
  })

  // `color: nil` leaves the bar's colours to the caller's `class:`, which is why the rule is
  // scoped to every `.navbar` and not to the four presets.
  it('the burger reads at 3:1 on a navbar coloured through class:, every theme', () => {
    open('base')
    // The classes `color: nil, class: 'bg-neutral text-neutral-content'` renders.
    cy.get('nav.navbar').then(($nav) => {
      $nav[0].classList.remove('navbar-base')
      $nav[0].classList.add('bg-neutral', 'text-neutral-content')
    })

    THEMES.forEach((theme) => {
      useTheme(theme)
      cy.get('nav.navbar').should(($nav) => {
        expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
        expect($nav.css('background-color'), 'the bar paints bg-neutral').not.to.equal('rgba(0, 0, 0, 0)')
        const burger = $nav[0].querySelector('[data-navbar-target="burger"]')
        expect(burger.matches(':hover'), 'measured at rest').to.equal(false)
        expect(paintedContrast(burger.querySelector('svg')), `${theme}: bg-neutral text-neutral-content navbar`).to.be.at.least(NON_TEXT)
      })
    })
  })

  // Why `currentColor` and not the preset's `-content`: the mobile menu inside the bar is
  // `bg-base-100 max-lg:text-base-content`. These pass without the rule too; what they catch is
  // the `-content` alternative, which a `base` bar cannot tell apart, so it is left out.
  COLORS.filter(color => color !== 'base').forEach((color) => {
    it(`a ghost button in the open menu of the ${color} navbar paints the menu's text colour`, () => {
      open(color)
      cy.get('[data-navbar-target="burger"]').click()

      cy.get('[data-navbar-target="menu"]').should(($menu) => {
        expect($menu.css('display'), 'the menu is open').to.equal('flex')
        expect($menu[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
        const ghost = $menu[0].querySelector('.btn-ghost')
        expect(window.getComputedStyle(ghost).color, `${color} navbar: the menu's text colour`).to.equal(window.getComputedStyle($menu[0]).color)
      })
    })
  })

  // The cases above that need the rule only reach the brand and the main burger; these pin the
  // rest of its reach: the desktop menu's ghost, the `:alt` burger and the `:sidebar` one.
  COLORS.filter(color => color !== 'base').forEach((color) => {
    it(`the ghost "Log in" of the desktop menu paints the text colour of the ${color} navbar`, () => {
      cy.viewport(1280, 800)
      open(color)

      cy.get('nav.navbar').should(($nav) => {
        expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
        const login = [...$nav[0].querySelectorAll('.btn-ghost')].find(b => b.textContent.trim() === 'Log in')
        expect(login.offsetWidth, 'the desktop menu shows at this width').to.be.greaterThan(0)
        expect(login.matches(':hover'), 'measured at rest').to.equal(false)
        expect(window.getComputedStyle(login).color, `${color} navbar: Log in`).to.equal(window.getComputedStyle($nav[0]).color)
      })
    })

    it(`the :alt burger paints the text colour of the ${color} navbar`, () => {
      open(color, '', 'with_multiple_menus')

      cy.get('nav.navbar').should(($nav) => {
        expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
        const alt = $nav[0].querySelector('[data-navbar-target="altBurger"]')
        expect(alt.offsetWidth, 'the alt burger shows at this width').to.be.greaterThan(0)
        expect(alt.matches(':hover'), 'measured at rest').to.equal(false)
        expect(window.getComputedStyle(alt).color, `${color} navbar: alt burger`).to.equal(window.getComputedStyle($nav[0]).color)
      })
    })

    it(`the :sidebar burger paints the text colour of the ${color} navbar`, () => {
      open(color, '&transparency=false', 'with_sidebar_burger')

      cy.get('nav.navbar').should(($nav) => {
        expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
        const trigger = $nav[0].querySelector('[data-controller~="side-menu-trigger"]')
        expect(trigger.offsetWidth, 'the sidebar burger shows at this width').to.be.greaterThan(0)
        expect(trigger.matches(':hover'), 'measured at rest').to.equal(false)
        expect(window.getComputedStyle(trigger).color, `${color} navbar: sidebar burger`).to.equal(window.getComputedStyle($nav[0]).color)
      })
    })
  })

  // The value keeps daisyUI's chain and only drops its base-content step. Green without the rule
  // too: what it catches is a bare `currentColor`.
  it('a ghost button with a colour of its own keeps it inside the bar', () => {
    open('neutral')
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

  // While the bar is transparent its ghost buttons follow its text colour, as its links do. This
  // pins the `.btn-ghost` rule, not where that colour comes from: it passes without the
  // `.is-transparent` rule's `color: inherit`, which navbar-transparent.cy.js pins. The bar goes
  // inside a container with a colour of its own because on the bare page it would inherit
  // base-content, which daisyUI paints a ghost button with anyway.
  it('the burger of a transparent coloured navbar paints the text colour of the bar', () => {
    open('primary', '&transparency=true')
    cy.get('nav.navbar').then(($nav) => {
      const container = $nav[0].ownerDocument.createElement('div')
      container.className = 'bg-neutral text-neutral-content'
      $nav[0].before(container)
      container.append($nav[0])
    })

    cy.get('nav.navbar').should('have.class', 'is-transparent').should(($nav) => {
      expect($nav[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
      const bar = window.getComputedStyle($nav[0]).color
      expect(bar, 'not the page\'s base-content').not.to.equal(window.getComputedStyle($nav[0].ownerDocument.body).color)
      const burger = $nav[0].querySelector('[data-navbar-target="burger"]')
      expect(burger.matches(':hover'), 'measured at rest').to.equal(false)
      expect(window.getComputedStyle(burger).color, 'the burger').to.equal(bar)
    })
  })
})
