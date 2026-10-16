// #1495 — a filter's column sizes to its content, so a percentage `max-width` on SlimSelect's
// value resolves against a box already sized to the text, and cuts it: «Beto» was drawn in
// 8.2 px of the 26 it needs, beside the ✕ that clears it.
describe('SimpleFilters: a slim_select filter', () => {
  it('shows the whole chosen value', () => {
    cy.visit('/bali/data_table/simple_filters/slim_select?owner=beto')

    cy.get('.ss-main .ss-deselect').should('not.have.class', 'ss-hide')
    cy.get('.ss-main .ss-single').should('have.text', 'Beto').and($single => {
      expect($single[0].scrollWidth, 'text width').to.be.at.most($single[0].clientWidth)
    })
  })

  // Below `sm` an iconed filter narrows (`slim_select_phone_width`). At the 64px the native
  // select takes, the ✕, the arrow, the padding and daisyUI's gap filled it: the value measured 0.
  // The text is measured with a Range: `scrollWidth` rounds, and read 26 of 26 for a «Be…» whose
  // text is 26.17px wide.
  it('shows a short chosen value whole, and its ✕, beside an icon at phone width', () => {
    cy.viewport(375, 700)
    cy.visit('/bali/data_table/simple_filters/with_icons?owner=beto')

    cy.get('.ss-main .ss-single').should('have.text', 'Beto').and($single => {
      const text = $single[0].ownerDocument.createRange()
      text.selectNodeContents($single[0])
      expect(text.getBoundingClientRect().width, 'text width').to.be.at.most($single[0].getBoundingClientRect().width)
    })
    cy.get('.ss-main .ss-deselect').click()
    cy.get('.ss-main .ss-placeholder').should('have.text', 'All owners')
  })
})
