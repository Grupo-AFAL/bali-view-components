// #1484 — `include_blank:` offers the blank as a value. On a flat list it is SlimSelect's
// placeholder, which the list leaves out, so the ✕ is the way back to it. The ✕ selects
// SlimSelect's first option, which is the blank only because slim_select_fields.rb puts the
// placeholder first.
describe('SlimSelect blank', () => {
  it('empties an include_blank select back to the blank with the ✕', () => {
    cy.visit('/bali/form/slim_select/optional_blank')
    cy.get('select[name="form_record[select]"]').as('select').should('have.value', '2')
    cy.get('#form_record_select_select_div .ss-main').as('main')

    cy.get('@main').find('.ss-deselect').should('not.have.class', 'ss-hide').click()

    cy.get('@select').should('have.value', '')
    cy.get('@main').find('.ss-values .ss-placeholder').should('have.text', 'None (top level)')
    cy.get('@main').find('.ss-deselect').should('have.class', 'ss-hide')
  })
})
