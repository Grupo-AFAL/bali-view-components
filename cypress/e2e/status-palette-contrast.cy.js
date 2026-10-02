import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'

// The palette's pairs at rest are test_every_palette_pair_reads_at_aa's job. What only a
// browser shows is a row of the editable panel under the pointer: the row's `:hover` rule
// is painted over the inline pair. `filter: brightness(.95)` dimmed the text with the fill
// and took pink from 4.60 to 4.49:1 (#1259).
//
// paintedContrast sees the row's fill and an overlay handed over as `under`. It does not see a
// `filter`, an inset `box-shadow`, an `opacity` on the panel or a pseudo-element, and in Chromium
// a <button>'s `::first-line` and `::first-letter` repaint its text. So the hover may change the
// row's background-image and nothing else computed for the row, its ancestors or their
// pseudo-elements. One run stands for all six themes only while that overlay is a flat black:
// a `color-mix` of base-content follows the theme, and its stops serialize as oklch(), not rgba().
describe('Status palette: hovered panel rows', () => {
  const AA = 4.5
  const FLAT_BLACK = /^linear-gradient\((rgba\(0, 0, 0, [\d.]+\)), \1\)$/
  const PSEUDOS = ['', '::before', '::after', '::first-line', '::first-letter']

  // Keyed by depth, 0 being the row.
  const paintOf = (row) => {
    const paint = {}
    for (let node = row, depth = 0; node; node = node.parentElement, depth++) {
      for (const pseudo of PSEUDOS) {
        const style = row.ownerDocument.defaultView.getComputedStyle(node, pseudo || null)
        for (const name of style) paint[`${depth}${pseudo} ${name}`] = style.getPropertyValue(name)
      }
    }
    return paint
  }

  // Hands `check` the hovered row and what the pointer changed on it and above it.
  const hoverRow = ($row, check) => {
    let rest
    cy.then(unhover)
    cy.wrap($row).should(([row]) => {
      const hoveredAtRest = row.ownerDocument.querySelector(':hover')
      expect(hoveredAtRest, `${row.textContent}: nothing hovered at rest`).to.equal(null)
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

        expect(changed, `${row.value}: what the hover changes`)
          .to.deep.equal(['0 background-image'])
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
