import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'

// The palette's pairs at rest are test_every_palette_pair_reads_at_aa's job. What only a
// browser shows is a row of the editable panel under the pointer: the row's `:hover` rule
// is painted over the inline pair. `filter: brightness(.95)` dimmed the text with the fill
// and took pink from 4.60 to 4.49:1 (#1259).
//
// paintedContrast sees neither a `filter` nor an inset `box-shadow`, and with either one in
// the hover rule it still passed, so both are asserted absent instead. One run stands for all
// six themes only while the overlay is a flat black, so that is asserted too: a `color-mix` of
// base-content follows the theme, and its stops serialize as oklch(), not rgba().
describe('Status palette: hovered panel rows', () => {
  const AA = 4.5
  const FLAT_BLACK_OR_NONE = /^none$|^linear-gradient\((rgba\(0, 0, 0, [\d.]+\)), \1\)$/

  afterEach(() => { unhover() })

  it('reads at 4.5:1 or more on every hovered row', () => {
    cy.visit('/bali/status/palette')
    cy.get('[data-status-target="trigger"]').click()

    cy.get('.status-option:not(.status-option--none)').should('have.length', 12).each(($row) => {
      cy.wrap($row).then(hover)
      cy.wrap($row).should(($hovered) => {
        const row = $hovered[0]
        const style = row.ownerDocument.defaultView.getComputedStyle(row)

        expect(row.matches(':hover'), `${row.value} under the pointer`).to.equal(true)
        expect(row.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
        expect(style.filter, `${row.value}: no filter dims the text`).to.equal('none')
        expect(style.boxShadow, `${row.value}: no inset shadow over the fill`).not.to.contain('inset')
        expect(style.backgroundImage, `${row.value}: a flat black overlay, or none`).to.match(FLAT_BLACK_OR_NONE)

        const [, overlay] = style.backgroundImage.match(FLAT_BLACK_OR_NONE)
        expect(paintedContrast(row, { under: overlay }), `${row.value} hovered`).to.be.at.least(AA)
      })
    })
  })
})
