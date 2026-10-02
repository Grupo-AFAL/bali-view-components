import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'

// The palette's pairs at rest are test_every_palette_pair_reads_at_aa's job. What only a
// browser shows is a row of the editable panel under the pointer: the row's `:hover` rule
// is painted over the inline pair. `filter: brightness(.95)` dimmed the text with the fill
// and took pink from 4.60 to 4.49:1 (#1259). The pair is inline and the overlay a fixed
// black, so no theme changes what this measures.
describe('Status palette: hovered panel rows', () => {
  const AA = 4.5

  afterEach(() => { unhover() })

  it('reads at 4.5:1 or more on every hovered row', () => {
    cy.visit('/bali/status/palette')
    cy.get('[data-status-target="trigger"]').click()

    cy.get('.status-option:not(.status-option--none)').should('have.length', 12).each(($row) => {
      cy.wrap($row).then(hover)
      cy.wrap($row).should(($hovered) => {
        const row = $hovered[0]
        const style = row.ownerDocument.defaultView.getComputedStyle(row)
        const overlay = new Set(style.backgroundImage.match(/rgba?\([^)]*\)/g))

        expect(row.matches(':hover'), `${row.value} under the pointer`).to.equal(true)
        expect(row.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
        expect(style.filter, `${row.value}: no filter dims the text`).to.equal('none')
        expect(overlay.size, `${row.value}: a flat overlay, or none`).to.be.at.most(1)
        expect(paintedContrast(row, { under: [...overlay][0] }), `${row.value} hovered`).to.be.at.least(AA)
      })
    })
  })
})
