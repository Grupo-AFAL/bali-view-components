import { paintedContrast } from '../support/painted_contrast'
import { BALI_THEMES as THEMES } from '../support/themes'

// The primary of every theme Bali ships, as painted: filled under its `-content` and as text on
// the page; the secondary filled under its own. `afal` shipped blue-500 under white, 3.68:1 on
// both, against AA's 4.5 for the 14px label of a button (#1221), and violet-500 under white at
// 4.23 (#1261). Text over a primary tint is not the theme's to carry: Bali paints it
// `text-soft-primary` (soft-text-contrast.cy.js). daisyUI's own `light` and `dark` are not Bali's
// to change: `dark` paints its primary button at 4.13:1, and both paint their secondary at 3.04.
// The secondary is not measured as text: `costa-norte`'s is a gold fill, 1.99:1 on the page, and
// where Bali writes a secondary on the page it paints `text-soft-secondary` (#1281).
describe('theme primary and secondary contrast', () => {
  const AA = 4.5
  // The selector is what proves the preview honoured its params: a `?variant=link` it ignored
  // renders `.btn-primary`, and the `get` fails instead of measuring the wrong button.
  const SURFACES = [
    ['the primary button', '/bali/button/default', '.btn-primary'],
    ['primary text on the page', '/bali/button/default?variant=link', '.btn-link'],
    ['the secondary button', '/bali/button/default?variant=secondary', '.btn-secondary']
  ]

  THEMES.forEach((theme) => {
    SURFACES.forEach(([surface, path, selector]) => {
      it(`reads ${surface} at AA on the ${theme} theme`, () => {
        cy.visit(path)
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get(selector).should(($el) => {
          expect($el[0].ownerDocument.getAnimations(), 'colour transitions settled').to.have.length(0)
          expect(paintedContrast($el[0]), `${theme}: ${surface}`).to.be.at.least(AA)
        })
      })
    })
  })
})
