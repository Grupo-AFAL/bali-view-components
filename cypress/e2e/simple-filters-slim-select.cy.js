// #1495 — a filter's column sizes to its content, so a percentage `max-width` on SlimSelect's
// value resolves against a box already sized to the text, and cuts it: «Beto» was drawn in
// 8.2 px of the 26 it needs, beside the ✕ that clears it.

// With a Range against the content width, not `scrollWidth`: docs/reference/testing-traps.md.
const expectWhole = $single => {
  const single = $single[0]
  const text = single.ownerDocument.createRange()
  text.selectNodeContents(single)
  const style = single.ownerDocument.defaultView.getComputedStyle(single)
  const inline = ['paddingLeft', 'paddingRight', 'borderLeftWidth', 'borderRightWidth'].reduce((sum, side) => sum + parseFloat(style[side]), 0)
  expect(text.getBoundingClientRect().width, 'text width').to.be.at.most(single.getBoundingClientRect().width - inline)
}

describe('SimpleFilters: a slim_select filter', () => {
  it('shows the whole chosen value', () => {
    cy.visit('/bali/data_table/simple_filters/slim_select?owner=beto')

    cy.get('.ss-main .ss-deselect').should('not.have.class', 'ss-hide')
    cy.get('.ss-main .ss-single').should('have.text', 'Beto').and(expectWhole)
  })

  // Below `sm` an iconed filter narrows (`slim_select_phone_width`) and still has to show a short
  // value whole beside the ✕, the only way back to «all» on a phone.
  it('shows a short chosen value whole, and its ✕, beside an icon at phone width', () => {
    cy.viewport(375, 700)
    cy.visit('/bali/data_table/simple_filters/with_icons?owner=beto')

    cy.get('.ss-main .ss-single').should('have.text', 'Beto').and(expectWhole)
    cy.get('.ss-main .ss-deselect').click()
    cy.get('.ss-main .ss-placeholder').should('have.text', 'All owners')
  })
})
