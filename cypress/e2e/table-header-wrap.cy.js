// A header's `nowrap` is daisyUI's `.table :where(thead, tfoot)`, inherited by the cell; a
// `whitespace-normal` on the header is the cell's own value and beats an inherited one at any
// layer. A `whitespace-nowrap` of Bali's on the cell would tie with it in `@layer utilities`,
// where `.whitespace-nowrap` is emitted after `.whitespace-normal` and wins (#1545).
describe('Table headers and white-space', () => {
  const header = 'thead th:last-child'
  const whiteSpace = ($el) => window.getComputedStyle($el[0]).whiteSpace

  it('keeps a header on one line by default', () => {
    cy.visit('/bali/table/wrapping_headers?wrap=false')
    cy.get(header).should(($th) => expect(whiteSpace($th)).to.equal('nowrap'))
  })

  it('wraps a header given whitespace-normal, so the table fits its panel', () => {
    cy.visit('/bali/table/wrapping_headers?wrap=true')
    cy.get('.table-component').should(($box) => {
      expect($box[0].scrollWidth).to.be.at.most($box[0].clientWidth)
    })
    cy.get(header).should(($th) => expect(whiteSpace($th)).to.equal('normal'))
  })
})
