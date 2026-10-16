// WCAG 2.5.8 asks for a pointer target of at least 24×24. The ✕ that clears a SlimSelect was as
// tall as its 12px glyph: 28×12, and 24×12 in a `sm` one. It grows for the pointer only, so the
// trigger it sits in keeps its height.
const expectTarget = (deselect, triggerHeight) => {
  const box = deselect.getBoundingClientRect()
  expect(box.width, 'width').to.be.at.least(24)
  expect(box.height, 'height').to.be.at.least(24)
  // What the pointer reaches, not only the box: the trigger could clip it.
  ;[[box.left + 1, box.top + 1], [box.right - 1, box.bottom - 1]].forEach(([x, y]) => {
    expect(deselect.contains(deselect.ownerDocument.elementFromPoint(x, y)), `hit at ${x}, ${y}`).to.equal(true)
  })
  expect(deselect.closest('.ss-main').getBoundingClientRect().height, 'trigger height').to.equal(triggerHeight)
}

describe('SlimSelect: the ✕ that clears the value', () => {
  ;[
    ['a form field', 1280, '/bali/form/slim_select/allow_deselect', 40],
    ['a filter', 1280, '/bali/data_table/simple_filters/slim_select?owner=beto', 32],
    ['an iconed filter on a phone', 375, '/bali/data_table/simple_filters/with_icons?owner=beto', 32]
  ].forEach(([where, width, path, triggerHeight]) => {
    it(`is a 24×24 target in ${where}`, () => {
      cy.viewport(width, 600)
      cy.visit(path)

      cy.get('.ss-main .ss-deselect').scrollIntoView().should($deselect => expectTarget($deselect[0], triggerHeight))
    })
  })

  // A trigger that sizes to its content: grown with padding alone, the ✕ took a `sm` multiple
  // holding chips from 32 to 36px. No preview has one, because SimpleFilters gives a multiple no
  // ✕; `allow_deselect_option: true` would show it, so the test shows it by hand.
  it('does not grow a `sm` multiple holding chips', () => {
    cy.viewport(1280, 600)
    cy.visit('/bali/data_table/simple_filters/multiple')
    cy.get('.ss-main').click()
    ;['USA', 'France'].forEach(country => cy.contains('.ss-content.ss-open .ss-option', new RegExp(`^${country}$`)).click())
    cy.get('.ss-value').should('have.length', 2)

    cy.get('.ss-main .ss-deselect').invoke('removeClass', 'ss-hide').should($deselect => expectTarget($deselect[0], 32))
  })
})
