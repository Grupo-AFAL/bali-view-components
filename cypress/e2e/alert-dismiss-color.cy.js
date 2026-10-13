import { paintedContrast, paintedPixel } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES, useTheme } from '../support/themes'

// The close X of an Alert (and so of a Toast) is a ghost Button, which daisyUI paints in
// base-content: on the dark themes a light X on a light solid alert, 1.37–2.67:1 (#1456).
//
// `bali/toast/all_colors` holds every colour in every style, each toast closable. Its
// `bali-toast-in` stays listed once it ends (`fill: both`), so only an animation still playing
// keeps a measurement waiting.
describe('Alert close button colour', () => {
  const ICON = 3

  const settled = doc =>
    expect(doc.getAnimations().filter(a => a.playState !== 'finished'), 'transitions settled').to.have.length(0)

  beforeEach(() => {
    cy.visit('/bali/toast/all_colors')
    cy.then(unhover)
  })
  afterEach(() => cy.then(unhover))

  it('paints the X in the alert text colour on every theme', () => {
    THEMES.forEach((theme) => {
      useTheme(theme)

      cy.get('.alert-component').should(($alerts) => {
        const alerts = $alerts.toArray()
        const doc = alerts[0].ownerDocument
        settled(doc)
        expect(alerts, 'five colours in four styles').to.have.length(20)

        alerts.forEach((alert) => {
          const x = alert.querySelector('.alert-dismiss')

          expect(x.matches(':hover'), 'at rest').to.equal(false)
          expect(paintedPixel(doc, getComputedStyle(x).color), `${theme}: ${alert.className}`)
            .to.deep.equal(paintedPixel(doc, getComputedStyle(alert).color))
          expect(paintedContrast(x), `${theme}: ${alert.className} X at rest`).to.be.at.least(ICON)
        })
      })
    })
  })

  // daisyUI paints the hover in `--btn-fg` over a base-200 disc. An unlayered `color: inherit`
  // would also win over the hover, and paint a dark X on that dark disc on the dark themes. The
  // first five toasts are the solid style, whose text is furthest from base-content.
  it('keeps the X legible under the pointer on every theme', () => {
    THEMES.forEach((theme) => {
      useTheme(theme)

      ;[0, 1, 2, 3, 4].forEach((index) => {
        cy.then(unhover)
        cy.get('.alert-dismiss').eq(index).then(hover)

        cy.get('.alert-dismiss').eq(index).should(([x]) => {
          settled(x.ownerDocument)
          expect(x.matches(':hover'), 'under the pointer').to.equal(true)
          expect(paintedContrast(x), `${theme}: ${x.closest('.alert-component').className} X under the pointer`)
            .to.be.at.least(ICON)
        })
      })
    })
  })
})
