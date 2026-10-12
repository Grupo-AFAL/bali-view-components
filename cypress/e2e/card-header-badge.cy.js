// Card::Header's badge ends its line, whether it fits beside the title or wraps below it.
// With `justify-between` on the row, a badge alone on its line after the wrap sat at the
// start, over 200 px short of the row's right edge at 375 px. Only a browser lays out the wrap.
describe('Card header badge', () => {
  const measure = (title) => cy.contains('h2.card-title', title).then(($title) => {
    const row = $title[0].closest('.card-body > div')
    const badge = row.querySelector('.badge').getBoundingClientRect()
    return {
      wrapped: badge.top >= row.firstElementChild.getBoundingClientRect().bottom,
      gapToRowEnd: row.getBoundingClientRect().right - badge.right
    }
  })

  beforeEach(() => {
    cy.viewport(375, 800)
    cy.visit('/bali/card/headers')
  })

  it('keeps a badge that wraps below a long title at the end of its line', () => {
    measure('Northern Industrial Warehouse').then(({ wrapped, gapToRowEnd }) => {
      expect(wrapped, 'the badge wraps below the title').to.equal(true)
      expect(gapToRowEnd).to.be.closeTo(0, 0.5)
    })
  })

  it('keeps a badge beside a short title at the end of the row', () => {
    measure('Notifications').then(({ wrapped, gapToRowEnd }) => {
      expect(wrapped, 'the badge fits beside the title').to.equal(false)
      expect(gapToRowEnd).to.be.closeTo(0, 0.5)
    })
  })
})
