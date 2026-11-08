// The mark sits in a box as tall as the title's first line (`min-h-8`, the 2rem line-height of
// `text-2xl`): a mark up to 32px is centred on that line however many lines the title wraps to,
// and a taller one grows the box rather than ride over what is above it.
describe('PageHeader title mark', () => {
  const box = (doc, selector) => doc.querySelector(selector).getBoundingClientRect()

  it('centres a 32px mark on the first line of a title that wraps', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/show_page/with_title_mark?mark_size=xs')
    cy.document().should((doc) => {
      const title = box(doc, 'h1')
      const mark = box(doc, '.page-header-title-mark > *')
      const lineHeight = parseFloat(window.getComputedStyle(doc.querySelector('h1')).lineHeight)
      expect(title.height).to.be.at.least(2 * lineHeight)
      expect(mark.top + mark.height / 2).to.be.closeTo(title.top + lineHeight / 2, 0.5)
    })
  })

  ;[[390, 844], [1280, 600]].forEach(([width, height]) => {
    it(`keeps a 48px mark from riding over the breadcrumbs and the title at ${width}px`, () => {
      cy.viewport(width, height)
      cy.visit('/bali/show_page/with_title_mark?mark_size=sm')
      cy.document().should((doc) => {
        const mark = box(doc, '.page-header-title-mark > *')
        expect(mark.height).to.equal(48)
        expect(mark.top).to.be.at.least(box(doc, '.breadcrumbs').bottom)
        expect(mark.top).to.be.at.least(box(doc, 'h1').top - 0.5)
      })
    })
  })
})
