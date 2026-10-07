import { paintedContrast, paintedPixel } from '../support/painted_contrast'
import { THEMES } from '../support/themes'

// The measurements are in the headers of button/daisyui-overrides.css and
// alert/daisyui-overrides.css. One visit per preview: the theme switches in place, and nothing is
// read until the switch's colour transitions have run (docs/reference/testing-traps.md).
describe('Tinted buttons and the error ink', () => {
  const AA = 4.5
  const NON_TEXT = 3

  const inTheme = (theme, check) => {
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
    cy.document().should((doc) => {
      expect(doc.getAnimations(), `${theme}: transitions settled`).to.have.length(0)
      check(doc)
    })
  }

  // What `text-soft-error` paints in the current theme, as a pixel.
  const errorInk = (doc) => {
    const probe = doc.createElement('span')
    probe.className = 'text-soft-error'
    doc.body.append(probe)
    const pixel = paintedPixel(doc, getComputedStyle(probe).color)
    probe.remove()
    return pixel
  }

  const expectErrorInk = (doc, els, theme) => {
    expect(els, 'error elements').to.have.length.at.least(1)
    els.forEach((el) => {
      expect(paintedPixel(doc, getComputedStyle(el).color), `${theme}: ${el.className}`)
        .to.deep.equal(errorInk(doc))
    })
  }

  it('paints error alerts in text-soft-error\'s ink, every theme', () => {
    cy.visit('/bali/alert/all_combinations')
    THEMES.forEach((theme) => {
      inTheme(theme, (doc) => {
        const alerts = [...doc.querySelectorAll('.alert-error:is(.alert-soft, .alert-outline, .alert-dash)')]
        expect(alerts, 'soft, outline and dash').to.have.length(3)
        expectErrorInk(doc, alerts, theme)
      })
    })
  })

  it('paints error tags in text-soft-error\'s ink, every theme', () => {
    cy.visit('/bali/tag/all_combinations')
    THEMES.forEach((theme) => {
      inTheme(theme, (doc) => {
        expectErrorInk(doc, [...doc.querySelectorAll('.badge-error:is(.badge-soft, .badge-outline, .badge-dash)')], theme)
      })
    })
  })

  it('reads coloured outline and soft buttons at AA at rest and rings a neutral one at 3:1, every theme', () => {
    cy.visit('/bali/button/all_combinations')

    THEMES.forEach((theme) => {
      inTheme(theme, (doc) => {
        // Primary keeps daisyUI's colour as text, which reads 3.16:1 at worst on daisyUI's `dark`.
        const tinted = [...doc.querySelectorAll('.btn:is(.btn-outline, .btn-soft):not(.btn-primary)')]
        expect(tinted, 'outline and soft, every colour but primary').to.have.length(14)
        tinted.forEach((button) => {
          expect(button.matches(':hover, :focus-visible'), `${button.className}: at rest`).to.equal(false)
          expect(paintedContrast(button), `${theme}: ${button.className}`).to.be.at.least(AA)
        })
        expectErrorInk(doc, tinted.filter(button => button.matches('.btn-error')), theme)
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
})
