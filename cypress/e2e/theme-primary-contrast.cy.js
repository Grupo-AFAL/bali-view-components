import { paintedContrast } from '../support/painted_contrast'

// The primary of every theme Bali ships, as painted: filled under its `-content`, as text on the
// page and as text on its own 10% tint. `afal` shipped blue-500 under white, 3.68:1 on the first
// two, against AA's 4.5 for the 14px label of a button (#1221); on the tint, Tailwind v3's
// blue-600 reads 4.49:1, which is why `afal` uses v4's. daisyUI's own `light` and `dark` are not
// Bali's to change, and `dark` paints its button at 4.13:1.
describe('theme primary contrast', () => {
  const AA = 4.5
  // The list test_the_expected_themes_ship_with_the_gem holds in test/bali/themes_test.rb.
  const THEMES = ['afal', 'afal-dark', 'costa-norte']
  // The selector is what proves the preview honoured its params: a `?variant=link` it ignored
  // renders `.btn-primary`, and the `get` fails instead of measuring the wrong button.
  const SURFACES = [
    ['the primary button', '/bali/button/default', '.btn-primary'],
    ['primary text on the page', '/bali/button/default?variant=link', '.btn-link'],
    ['primary text on its 10% tint', '/bali/side_menu/default', '.menu-item.side-menu-expanded[aria-current="page"]']
  ]

  THEMES.forEach((theme) => {
    SURFACES.forEach(([surface, path, selector]) => {
      it(`reads ${surface} at AA on the ${theme} theme`, () => {
        cy.visit(path)
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get(selector).should(($el) => {
          expect($el[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
          expect(paintedContrast($el[0]), `${theme}: ${surface}`).to.be.at.least(AA)
        })
      })
    })
  })
})
