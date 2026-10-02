import { luminance } from '../support/painted_contrast'
import { THEMES } from '../support/themes'
import { hover, unhover } from '../support/tap'

// The palette's pairs at rest are test_every_palette_pair_reads_at_aa's job. What only a
// browser shows is a row of the editable panel under the pointer: the row's `:hover` rule
// is painted over the inline pair. `filter: brightness(.95)` dimmed the text with the fill
// and took pink from 4.60 to 4.49:1 (#1259).
describe('Status palette: hovered panel rows', () => {
  const AA = 4.5

  afterEach(() => { unhover() })

  // paintedContrast sees neither a `filter`, which darkens the text along with the fill,
  // nor a `background-image`, which lies over the fill and under the text.
  const hoveredContrast = (row) => {
    const doc = row.ownerDocument
    const style = doc.defaultView.getComputedStyle(row)
    const canvas = doc.createElement('canvas')
    canvas.width = canvas.height = 1
    const ctx = canvas.getContext('2d', { willReadFrequently: true })
    const paint = (colour) => {
      ctx.fillStyle = colour
      ctx.fillRect(0, 0, 1, 1)
      return [...ctx.getImageData(0, 0, 1, 1).data].slice(0, 3)
    }

    expect(style.filter, 'a filter this measurement can apply').to.match(/^(none|brightness\([\d.]+\))$/)
    const stops = style.backgroundImage === 'none' ? [] : style.backgroundImage.match(/rgba?\([^)]*\)/g) || []
    expect(stops.length > 0 || style.backgroundImage === 'none', 'an overlay made of colour stops').to.equal(true)
    expect(new Set(stops).size, 'a flat overlay').to.be.at.most(1)

    let fill = paint(style.backgroundColor)
    if (stops.length) fill = paint(stops[0])
    ctx.clearRect(0, 0, 1, 1)
    const ink = paint(style.color)
    const brightness = Number((/brightness\(([\d.]+)\)/.exec(style.filter) || [])[1] ?? 1)

    const [high, low] = [fill, ink]
      .map((colour) => luminance(colour.map((channel) => channel * brightness)))
      .sort((a, b) => b - a)
    return (high + 0.05) / (low + 0.05)
  }

  THEMES.forEach((theme) => {
    it(`reads at 4.5:1 or more on every hovered row on the ${theme} theme`, () => {
      cy.visit('/bali/status/palette')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))
      cy.get('[data-status-target="trigger"]').click()

      cy.get('.status-option:not(.status-option--none)').should('have.length', 12).each(($row) => {
        cy.wrap($row).then(hover)
        cy.wrap($row).should(($hovered) => {
          const row = $hovered[0]
          expect(row.matches(':hover'), `${row.value} under the pointer`).to.equal(true)
          expect(row.ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)
          expect(hoveredContrast(row), `${theme}: ${row.value} hovered`).to.be.at.least(AA)
        })
      })
    })
  })
})
