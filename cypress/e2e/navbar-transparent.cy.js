import { paintedContrast } from '../support/painted_contrast'
import { THEMES, token } from '../support/themes'

// A transparent bar shows whatever is under it, which its `color:` preset knows nothing about.
// Painting its preset's `-content` over the page, its links measured 1.00:1 on a `primary` bar in
// `afal` and fell under 3:1 in 15 of the 24 colour × theme pairs (#1284).
describe('Navbar: a transparent bar', () => {
  const TEXT = 4.5
  const COLORS = ['primary', 'secondary', 'accent', 'neutral']

  const open = (color, theme, preview = 'default', query = '&transparency=true') => {
    cy.visit(`/bali/navbar/${preview}?color=${color}${query}`)
    // Proves the preview honoured `?color=`: one it ignored renders `navbar-base`.
    cy.get('nav.navbar').should('have.class', `navbar-${color}`).and('have.class', 'is-transparent')
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
  }

  const byText = (nav, text) => [...nav.querySelectorAll('a')].find(a => a.textContent.trim() === text)

  THEMES.forEach((theme) => {
    COLORS.forEach((color) => {
      it(`its links read on the page, ${color} bar, ${theme} theme`, () => {
        cy.viewport(1280, 800)
        open(color, theme)

        cy.document().should((doc) => {
          expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
          const nav = doc.querySelector('nav.navbar')
          ;['Home', 'LOGO', 'Log in'].forEach((text) => {
            const link = byText(nav, text)
            expect(link.offsetWidth, `${text} shows at this width`).to.be.greaterThan(0)
            expect(link.matches(':hover'), 'measured at rest').to.equal(false)
            expect(paintedContrast(link), `${theme}: ${text} on a transparent ${color} bar`).to.be.at.least(TEXT)
          })
        })
      })
    })
  })

  // The page's colour while it is transparent, and not base-content: a bar rendered inside a
  // container that has a colour of its own (a dark section) reads in that colour, over it.
  it('inside a container with a text colour of its own, it paints that colour', () => {
    cy.viewport(1280, 800)
    open('accent', 'afal')
    cy.get('nav.navbar').then(($nav) => {
      const section = $nav[0].ownerDocument.createElement('div')
      section.className = 'bg-neutral text-neutral-content'
      $nav[0].before(section)
      section.append($nav[0])
    })

    cy.document().should((doc) => {
      expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
      const nav = doc.querySelector('nav.navbar')
      expect(nav.classList.contains('is-transparent'), 'still transparent after the move').to.equal(true)
      const home = byText(nav, 'Home')
      expect(window.getComputedStyle(nav).color, 'the container\'s colour').to.equal(window.getComputedStyle(nav.parentElement).color)
      expect(paintedContrast(home), 'Home over the container').to.be.at.least(TEXT)
    })
  })

  // The YARD example of `transparency:`, over a dark section: `color: :neutral, class:
  // "text-neutral-content"`. A host's text utility has to beat `.is-transparent`, which is why
  // that rule sits in @layer components and not in an unlayered sheet.
  it('a text colour passed in class: beats the colour it inherits', () => {
    cy.viewport(1280, 800)
    open('neutral', 'light')
    cy.get('nav.navbar').then(($nav) => {
      const section = $nav[0].ownerDocument.createElement('div')
      section.className = 'bg-neutral'
      $nav[0].before(section)
      section.append($nav[0])
      $nav[0].classList.add('text-neutral-content')
    })

    cy.document().should((doc) => {
      expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0)
      const nav = doc.querySelector('nav.navbar')
      expect(nav.classList.contains('is-transparent'), 'still transparent after the move').to.equal(true)
      expect(window.getComputedStyle(nav).color, 'neutral-content').to.equal(token(nav, 'neutral-content'))
      expect(paintedContrast(byText(nav, 'Home')), 'Home over the dark section').to.be.at.least(TEXT)
    })
  })

  // `with_sidebar_burger` is two viewports tall and transparent by default.
  it('takes its preset text colour back with its background, and leaves it again at the top', () => {
    open('neutral', 'afal', 'with_sidebar_burger', '')
    cy.document().should(doc => expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0))

    cy.scrollTo(0, 600)
    cy.get('nav.navbar').should('not.have.class', 'is-transparent').should(($nav) => {
      expect(window.getComputedStyle($nav[0]).color, 'neutral-content').to.equal(token($nav[0], 'neutral-content'))
    })

    cy.scrollTo(0, 0)
    cy.get('nav.navbar').should('have.class', 'is-transparent').should(($nav) => {
      expect(token($nav[0], 'neutral-content'), 'two colours to tell apart').not.to.equal(token($nav[0], 'base-content'))
      expect(window.getComputedStyle($nav[0]).color, 'the page\'s text colour').to.equal(window.getComputedStyle($nav[0].parentElement).color)
    })
  })

  // The server renders `is-transparent`, so a bar that connects on a page already scrolled past
  // it (a restored scroll position) takes its background back on connecting, not on the next
  // scroll. The served markup is put back in place of the bar, which connects a new controller.
  it('connecting below the threshold takes its background back', () => {
    open('neutral', 'afal', 'with_sidebar_burger', '')
    cy.scrollTo(0, 600)
    cy.get('nav.navbar').should('not.have.class', 'is-transparent').then(($nav) => {
      const served = $nav[0].cloneNode(true)
      served.classList.add('is-transparent')
      served.dataset.served = ''
      $nav[0].replaceWith(served)
    })

    cy.window().its('scrollY').should('be.greaterThan', 100)
    cy.get('nav.navbar[data-served]').should('not.have.class', 'is-transparent')
  })

  // Text colour and background swap at the threshold, so anything that fades one of them leaves
  // the links on a background they were not made for: with the bar's 1 s background fade,
  // `secondary` in `light` read under 3:1 for ~830 ms going down. The moment the controller flips
  // the class, every transition in the bar is paused and walked through in 10 ms steps, so a slow
  // frame on the runner cannot hide one.
  const BRIEF = 100
  const STEP = 10

  const watchCrossings = (nav) => {
    const win = nav.ownerDocument.defaultView
    win.crossings = []
    new win.MutationObserver(() => {
      const transitions = nav.getAnimations({ subtree: true })
      transitions.forEach(transition => transition.pause())
      const end = Math.max(0, ...transitions.map(transition => transition.effect.getComputedTiming().endTime))
      let under = 0
      for (let time = 0; time <= end; time += STEP) {
        transitions.forEach((transition) => { transition.currentTime = time })
        if (['Home', 'LOGO'].some(text => paintedContrast(byText(nav, text)) < 3)) under += STEP
      }
      transitions.forEach(transition => transition.finish())
      win.crossings.push({ transparent: nav.classList.contains('is-transparent'), under })
    }).observe(nav, { attributeFilter: ['class'] })
  }

  THEMES.forEach((theme) => {
    COLORS.forEach((color) => {
      it(`changes its text colour with its background, both ways, ${color} bar, ${theme} theme`, () => {
        cy.viewport(1280, 800)
        open(color, theme, 'with_sidebar_burger', '')
        cy.document().should(doc => expect(doc.getAnimations(), 'colour transitions settled').to.have.length(0))
        cy.get('nav.navbar').then($nav => watchCrossings($nav[0]))

        ;[['down', 600], ['up', 0]].forEach(([direction, y], index) => {
          cy.scrollTo(0, y)
          cy.window().its('crossings').should((crossings) => {
            expect(crossings, `crossings after scrolling ${direction}`).to.have.length(index + 1)
            expect(crossings[index].transparent, 'transparent after it').to.equal(direction === 'up')
            expect(crossings[index].under, `${theme}: ms under 3:1 crossing ${direction}`).to.be.at.most(BRIEF)
          })
        })
      })
    })
  })
})
