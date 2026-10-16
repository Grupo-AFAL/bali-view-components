// The Select all / Deselect all buttons `select_all: true` draws over a multiple select, on a
// list in option groups. What they select is read off the native <select>, which is what the
// form sends.
const PREVIEW = '/bali/form/slim_select/select_all?grouped=true'

const selectedValues = select => [...select.selectedOptions].map(option => option.value)

describe('SlimSelect select all', () => {
  beforeEach(() => {
    cy.visit(PREVIEW)
    cy.get('#form_record_name_select_div .ss-main').should('exist')
    cy.get('#form_record_name option:disabled').should('have.value', 'butter')
  })

  it('selects every enabled option inside the option groups', () => {
    cy.get('[data-slim-select-target="selectAllButton"]').click()

    cy.get('#form_record_name').should(([select]) => {
      expect(selectedValues(select)).to.deep.equal([
        'apple', 'banana', 'orange', 'carrot', 'broccoli', 'spinach', 'milk', 'cheese', 'yogurt'
      ])
    })
  })

  it('deselects them all again', () => {
    cy.get('[data-slim-select-target="selectAllButton"]').click()
    cy.get('#form_record_name option:checked').should('have.length', 9)

    cy.get('[data-slim-select-target="deselectAllButton"]').click()

    cy.get('#form_record_name option:checked').should('have.length', 0)
  })
})
