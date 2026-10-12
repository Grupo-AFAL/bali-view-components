// #1424. A size class on an Icon used to size only the wrapper: the template's
// `*:h-4 *:w-4` sat in @layer utilities and held the glyph at 16px. Who wins the
// cascade is something only a browser can say.
const SQUARE = {
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

const measure = $icon => {
  const box = $icon[0].getBoundingClientRect()
  const glyph = $icon[0].firstElementChild.getBoundingClientRect()
  return { box, glyph }
}

describe('Icon sizing', () => {
  beforeEach(() => {
    cy.visit('/bali/icon/sizing')
  })

  Object.entries(SQUARE).forEach(([id, px]) => {
    it(`draws #${id} at ${px}px, glyph and box alike`, () => {
      cy.get(`#${id}`).should($icon => {
        const { box, glyph } = measure($icon)
        expect([glyph.width, glyph.height], 'glyph').to.deep.equal([px, px])
        expect([box.width, box.height], 'box').to.deep.equal([px, px])
      })
    })
  })

  // The two boxes an unsized Icon has always had: with a fixed default the box sat at the
  // top of the row, and its own padding squeezed it down to the glyph.
  it('stretches an unsized icon in a flex row and keeps the glyph centred', () => {
    cy.get('#icon-stretched').should($icon => {
      const { box, glyph } = measure($icon)
      expect(box.height, 'box').to.equal(46)
      expect([glyph.width, glyph.height], 'glyph').to.deep.equal([16, 16])
      expect(glyph.top + glyph.height / 2, 'glyph centre').to.equal(box.top + box.height / 2)
    })
  })

  it('grows an unsized icon with its own padding', () => {
    cy.get('#icon-padded').should($icon => {
      const { box, glyph } = measure($icon)
      expect([box.width, box.height], 'box').to.deep.equal([32, 32])
      expect([glyph.width, glyph.height], 'glyph').to.deep.equal([16, 16])
    })
  })

  // A glyph sized in percent counts as 0 towards the row's minimum: the row squeezed this
  // one to 0x24.
  it('keeps a sized icon whole in a tight flex row', () => {
    cy.get('#icon-tight').should($icon => {
      const { box, glyph } = measure($icon)
      expect([glyph.width, glyph.height], 'glyph').to.deep.equal([24, 24])
      expect(box.width, 'box').to.equal(24)
    })
  })

  // `inline-flex` written on the element outranked it, and the icon stayed on screen.
  it('lets a display utility win', () => {
    cy.get('#icon-hidden').should('have.css', 'display', 'none')
  })
})
