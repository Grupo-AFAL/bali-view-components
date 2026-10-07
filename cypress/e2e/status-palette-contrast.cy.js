import { paintedContrast } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'
import { THEMES } from '../support/themes'

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
describe('Status palette contrast', () => {
  const AA = 4.5
  const NON_TEXT = 3
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

  const expectFlatBlackAtAA = (row, changed, what) => {
    const { backgroundImage } = row.ownerDocument.defaultView.getComputedStyle(row)

    expect(changed, `${what}: what the hover changes`).to.deep.equal(['0 background-image'])
    expect(backgroundImage, `${what}: a flat black overlay`).to.match(FLAT_BLACK)

    const [, overlay] = backgroundImage.match(FLAT_BLACK)
    expect(paintedContrast(row, { under: overlay }), `${what} hovered`).to.be.at.least(AA)
  }

  const caretContrast = (caret) => paintedContrast(caret, { property: 'borderTopColor' })

  afterEach(() => { unhover() })

  it('paints only a flat black overlay on a hovered colour row, at 4.5:1 or more', () => {
    cy.visit('/bali/status/palette')
    cy.get('[data-status-target="trigger"]').click()

    cy.get('.status-option:not(.status-option--none)').should('have.length', 12).each(($row) => {
      hoverRow($row, (row, changed) => expectFlatBlackAtAA(row, changed, row.value))
    })
  })

  // The caret is drawn in the pill's text colour and is what tells an editable pill from a
  // read-only one, so it owes WCAG 1.4.11's 3:1 against the pill. At `opacity: 0.7` it read
  // 2.89:1 on pink and 2.99 on red. The pairs are inline, so one theme stands for six.
  it('draws the caret of every colour at 3:1 on its pill', () => {
    cy.visit('/bali/status/palette?editable=true')

    cy.get('.status-pill:not(.status-pill--none) .status-pill__caret').should(($carets) => {
      expect($carets, 'a caret per colour').to.have.length(12)
      $carets.each((_, caret) => {
        const colour = caret.closest('.status-pill').textContent.trim()
        expect(caretContrast(caret), `${colour} caret`).to.be.at.least(NON_TEXT)
      })
    })
  })

  // No status is base-content mixed with transparent, over the page under the pill and over the
  // panel under its row, so it follows the theme: mixed at 60% the text read 4.04:1 on `afal`
  // and 4.32 on `costa-norte`.
  it('reads the no-status pill, its caret and its panel row at AA on every theme', () => {
    cy.visit('/bali/status/palette')
    THEMES.forEach((theme) => {
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.status-pill--none').should('have.length', 1).should(([pill]) => {
        expect(pill.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
        expect(paintedContrast(pill.querySelector('.status-pill__label > span')), `${theme}: pill text`)
          .to.be.at.least(AA)
        expect(caretContrast(pill.querySelector('.status-pill__caret')), `${theme}: pill caret`)
          .to.be.at.least(NON_TEXT)
      })
    })

    cy.get('[data-status-target="trigger"]').click()
    THEMES.forEach((theme) => {
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.status-option--none').should('have.length', 1).should(([row]) => {
        expect(row.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
        expect(paintedContrast(row), `${theme}: row text`).to.be.at.least(AA)
      }).then(($row) => {
        hoverRow($row, (row, changed) => expectFlatBlackAtAA(row, changed, `${theme}: row`))
      })
    })
  })
})
