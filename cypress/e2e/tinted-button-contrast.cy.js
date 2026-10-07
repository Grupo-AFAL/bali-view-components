import { paintedContrast, paintedPixel } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The measurements are in the header of button/index.css. Link's reference page renders every
// colour in each fill with the classes Button does (Bali::ButtonTaxonomy). One visit: the theme
// switches in place, and nothing is read until its colour transitions have run
// (docs/reference/testing-traps.md).
describe('Tinted buttons', () => {
  const AA = 4.5
  const NON_TEXT = 3
  // Primary keeps daisyUI's colour as text, which reads 3.16:1 at worst on daisyUI's `dark`.
  const TINTED = ':is(.btn-secondary, .btn-accent, .btn-info, .btn-success, .btn-warning, .btn-error, .btn-neutral):is(.btn-outline, .btn-soft)'

  const inTheme = (theme, check) => {
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
    cy.document().should((doc) => {
      expect(doc.getAnimations(), `${theme}: transitions settled`).to.have.length(0)
      check(doc)
    })
  }

  const pixel = (el, property = 'color') => paintedPixel(el.ownerDocument, getComputedStyle(el)[property])

  // What `text-soft-error` paints in the current theme.
  const errorInk = (doc) => {
    const probe = doc.createElement('span')
    probe.className = 'text-soft-error'
    doc.body.append(probe)
    const ink = pixel(probe)
    probe.remove()
    return ink
  }

  it('reads coloured outline and soft buttons at AA at rest and rings a neutral one at 3:1, every theme', () => {
    cy.visit('/bali/link/reference')

    THEMES.forEach((theme) => {
      inTheme(theme, (doc) => {
        const tinted = [...doc.querySelectorAll(TINTED)]
        expect(tinted, 'outline and soft, every colour but primary, twice').to.have.length(28)
        tinted.forEach((button) => {
          expect(button.matches(':hover, :focus-visible'), `${button.className}: at rest`).to.equal(false)
          expect(paintedContrast(button), `${theme}: ${button.className}`).to.be.at.least(AA)
        })
        const errors = tinted.filter(button => button.matches('.btn-error'))
        expect(errors, 'error outline and soft, twice').to.have.length(4)
        errors.forEach((button) => {
          expect(pixel(button), `${theme}: ${button.className} in text-soft-error's ink`).to.deep.equal(errorInk(doc))
        })
      })
    })

    THEMES.forEach((theme) => {
      ;[':not(.btn-outline, .btn-soft)', '.btn-outline', '.btn-soft'].forEach((style) => {
        const selector = `.btn-neutral${style}`
        cy.get(selector).then($button => $button[0].focus())
        inTheme(theme, (doc) => {
          const button = doc.activeElement
          expect(button.matches(`${selector}:focus-visible`), `${selector}: keyboard focus`).to.equal(true)
          expect(getComputedStyle(button).outlineStyle, `${selector}: ring drawn`).to.equal('solid')
          expect(paintedContrast(button, { over: button.parentElement, property: 'outlineColor' }), `${theme}: ${selector} ring`)
            .to.be.at.least(NON_TEXT)
        })
      })
    })
  })

  // The measurement is in navbar/index.css, next to the rule.
  it('keeps daisyUI\'s colour on an outline button over a coloured Navbar', () => {
    cy.visit('/bali/navbar/default?color=neutral')
    cy.get('nav.navbar').then(([nav]) => {
      nav.insertAdjacentHTML('beforeend', ['outline', 'soft'].map(style =>
        `<button type="button" class="btn btn-warning btn-${style}">${style}</button>`).join(''))
    })

    inTheme('afal', (doc) => {
      const [outline, soft] = doc.querySelectorAll('nav.navbar > .btn-warning')
      expect(pixel(outline), 'outline text in its own colour').to.deep.equal(pixel(outline, 'borderTopColor'))
      expect(paintedContrast(outline), 'outline over the bar').to.be.at.least(AA)
      expect(paintedContrast(soft), 'soft on its own ground').to.be.at.least(AA)
    })
  })
})
