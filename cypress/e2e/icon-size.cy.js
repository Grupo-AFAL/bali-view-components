// #1424. A size class on an Icon used to size only the wrapper: the template's
// `*:h-4 *:w-4` sat in @layer utilities and held the glyph at 16px. Who wins the
// cascade is something only a browser can say.
const CASES = {
  'icon-default': 16,
  'icon-size-class': 24,
  // `.size-3.5` is emitted before `.size-4`, so a default written as a utility beat it.
  'icon-small-class': 14,
  'icon-width-height': 20,
  'icon-named': 32,
  'icon-numeric': 24,
  // An inline `width` from `size:` would have kept this at 24.
  'icon-numeric-and-class': 32,
  // A kept SVG, not Lucide: it carries no width or height attribute at all.
  'icon-kept': 40
}

describe('Icon sizing', () => {
  beforeEach(() => {
    cy.visit('/bali/icon/sizing')
  })

  Object.entries(CASES).forEach(([id, px]) => {
    it(`draws #${id} at ${px}px, glyph and box alike`, () => {
      cy.get(`#${id}`).should($icon => {
        const box = $icon[0].getBoundingClientRect()
        const glyph = $icon[0].firstElementChild.getBoundingClientRect()
        expect([glyph.width, glyph.height], 'glyph').to.deep.equal([px, px])
        expect([box.width, box.height], 'box').to.deep.equal([px, px])
      })
    })
  })
})
