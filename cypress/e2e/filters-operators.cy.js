// #1566 — an attribute's `operators:` and `default_operator:` travel on its <option> as
// data-operators and data-default-operator (Bali::Filters::Operators.for_attribute and
// .default_for), which condition_controller.js#updateOperators reads when the attribute is
// picked. test/bali/components/filters/condition/component_test.rb holds the server side.
describe('An attribute that declares its operators', () => {
  const attribute = () => cy.get('[data-condition-target="attribute"]').first()
  const operator = () => cy.get('[data-condition-target="operator"]').first()
  const offered = ($select) => Array.from($select[0].options).map((option) => option.value)

  beforeEach(() => {
    cy.visit('/bali/filters/restricted_operators?popover=false')
  })

  it('opens a condition on its only operator, fixed', () => {
    attribute().select('employee_id')

    operator().should(($select) => {
      expect(offered($select)).to.deep.equal(['eq'])
      expect($select[0].value).to.equal('eq')
      expect($select[0].disabled, 'a single operator is fixed').to.equal(true)
    })
    cy.get('[data-condition-target="valueContainer"] input').first()
      .should('have.attr', 'name', 'q[g][0][employee_id_eq]')
  })

  it('opens on its default operator and still offers the rest of its type', () => {
    attribute().select('folio')

    operator().should(($select) => {
      expect($select[0].value).to.equal('eq')
      expect(offered($select)).to.include.members(['cont', 'start', 'not_eq'])
      expect($select[0].disabled).to.equal(false)
    })
  })

  it('narrows a date to the operators it declares, in their order', () => {
    attribute().select('created_at')

    operator().should(($select) => {
      expect(offered($select)).to.deep.equal(['between', 'eq'])
      expect($select[0].value).to.equal('between')
    })
    cy.get('[data-condition-target="rangeInput"]').should('exist')
  })

  // The row keeps the operator it had when the attribute declares none: a between carried to
  // another date field (filters-between.cy.js) depends on it.
  it('leaves an attribute that declares nothing on the operator the row had', () => {
    attribute().select('folio')
    operator().select('start')
    attribute().select('name')

    operator().should(($select) => {
      expect($select[0].value).to.equal('start')
      expect($select[0].disabled).to.equal(false)
    })
  })

  it('frees the select again when the next attribute offers more than one', () => {
    attribute().select('employee_id')
    operator().should('be.disabled')
    attribute().select('name')

    operator().should(($select) => {
      expect($select[0].disabled).to.equal(false)
      expect(offered($select)).to.have.length(6)
    })
  })
})
