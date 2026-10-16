// The Select all / Deselect all buttons `select_all: true` draws over a multiple select. What
// they select is read off the native <select>, which is what the form sends.
const visit = query => {
  cy.visit(`/bali/form/slim_select/select_all?${query}`)
  cy.get('#form_record_name_select_div .ss-main').should('exist')
}

const selectedValues = select => [...select.selectedOptions].map(option => option.value)

const listOption = text => cy.contains('.ss-content.ss-open .ss-option', text)

describe('SlimSelect select all', () => {
  describe('over option groups, with a disabled option and a disabled group', () => {
    beforeEach(() => {
      visit('grouped=true')
      cy.get('#form_record_name option:disabled').should(options => {
        expect([...options].map(option => option.value)).to.deep.equal(['butter', 'peas', 'sorbet'])
      })
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

    it('does not let an option of a disabled group be picked', () => {
      cy.get('#form_record_name_select_div .ss-main').click()
      listOption('Peas').should('have.class', 'ss-disabled').click()

      cy.get('#form_record_name option:checked').should('have.length', 0)
    })

    it('does not let an option of a disabled group added later be picked', () => {
      cy.get('#form_record_name').then(([select]) => {
        const group = select.ownerDocument.createElement('optgroup')
        group.label = 'Late'
        group.disabled = true
        group.innerHTML = '<option value="late">Late item</option>'
        select.append(group)
      })

      cy.get('#form_record_name_select_div .ss-main').click()
      listOption('Late item').should('have.class', 'ss-disabled')
    })
  })

  it('leaves the include_blank placeholder out', () => {
    visit('blank=true')

    cy.get('[data-slim-select-target="selectAllButton"]').click()

    cy.get('#form_record_name').should(([select]) => {
      expect(selectedValues(select)).to.deep.equal(['1', '2', '3', '4', '5'])
    })
  })
})
