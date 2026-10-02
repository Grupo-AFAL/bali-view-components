import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'

// The palette's pairs at rest are test_every_palette_pair_reads_at_aa's job. What only a
// browser shows is a row of the editable panel under the pointer: the row's `:hover` rule
// is painted over the inline pair. `filter: brightness(.95)` dimmed the text with the fill
// and took pink from 4.60 to 4.49:1 (#1259).
//
// paintedContrast sees the row's fill and an overlay handed over as `under`, but not a
// `filter`, an inset `box-shadow` or a pseudo-element drawn over the text, so the hover may
// change the row's background-image and no other computed property of the row or of its
// pseudo-elements. One run stands for all six themes only while that overlay is a flat black:
// a `color-mix` of base-content follows the theme, and its stops serialize as oklch(), not rgba().
describe('Status palette: hovered panel rows', () => {
  const AA = 4.5
  const FLAT_BLACK = /^linear-gradient\((rgba\(0, 0, 0, [\d.]+\)), \1\)$/

  const paintOf = (row) => {
    const paint = {}
    for (const pseudo of ['', '::before', '::after']) {
      const style = row.ownerDocument.defaultView.getComputedStyle(row, pseudo || null)
      for (const name of style) paint[`${pseudo} ${name}`.trim()] = style.getPropertyValue(name)
    }
    return paint
  }

  // Hands `check` the hovered row and the properties the pointer changed on it.
  const hoverRow = ($row, check) => {
    let rest
    cy.wrap($row).should(([row]) => {
      expect(row.ownerDocument.getAnimations(), 'transitions settled at rest').to.have.length(0)
      rest = paintOf(row)
    })
    cy.wrap($row).then(hover)
    cy.wrap($row).should(([row]) => {
      expect(row.matches(':hover'), `${row.textContent} under the pointer`).to.equal(true)
      expect(row.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
      const hovered = paintOf(row)
      check(row, Object.keys(hovered).filter((name) => hovered[name] !== rest[name]))
    })
  }

  afterEach(() => { unhover() })

  it('paints only a flat black overlay on a hovered colour row, at 4.5:1 or more', () => {
    cy.visit('/bali/status/palette')
    cy.get('[data-status-target="trigger"]').click()

    cy.get('.status-option:not(.status-option--none)').should('have.length', 12).each(($row) => {
      hoverRow($row, (row, changed) => {
        const { backgroundImage } = row.ownerDocument.defaultView.getComputedStyle(row)

        expect(changed, `${row.value}: what the hover changes`).to.deep.equal(['background-image'])
        expect(backgroundImage, `${row.value}: a flat black overlay`).to.match(FLAT_BLACK)

        const [, overlay] = backgroundImage.match(FLAT_BLACK)
        expect(paintedContrast(row, { under: overlay }), `${row.value} hovered`).to.be.at.least(AA)
      })
    })
  })

  // The black over the bare panel would take the row's muted text from 4.66 to 4.48:1 on `light`.
  it('leaves the no-status row as it is under the pointer', () => {
    cy.visit('/bali/status/editable')
    cy.get('[data-status-target="trigger"]').click()

    cy.get('.status-option--none').should('have.length', 1).then(($row) => {
      hoverRow($row, (_row, changed) => {
        expect(changed, 'what the hover changes').to.deep.equal([])
      })
    })
  })
})
