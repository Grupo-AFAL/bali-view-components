import { paintedContrast } from '../support/painted_contrast'

// The primary of every theme Bali ships, as painted: filled under its `-content` and as text on
// the page. `afal` shipped blue-500 under white, 3.68:1 on both, against AA's 4.5 for the 14px
// label of a button (#1221). daisyUI's own `light` and `dark` are not Bali's to change, and
// `dark` paints its button at 4.13:1.
describe('theme primary contrast', () => {
  const AA = 4.5
  const THEMES = ['afal', 'afal-dark', 'costa-norte']
  const SURFACES = [
    ['the primary button', '/bali/button/default'],
    ['primary text on the page', '/bali/button/default?variant=link']
  ]

  THEMES.forEach((theme) => {
    SURFACES.forEach(([surface, path]) => {
      it(`reads ${surface} at AA on the ${theme} theme`, () => {
        cy.visit(path)
        cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

        cy.get('.btn').should(($button) => {
          expect($button[0].getAnimations({ subtree: true }), 'colour transitions settled').to.have.length(0)
          expect(paintedContrast($button[0]), `${theme}: ${surface}`).to.be.at.least(AA)
        })
      })
    })
  })
})
