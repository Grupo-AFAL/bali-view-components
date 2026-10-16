// #1484 — `include_blank:` offers the blank as a value. On a flat list it is SlimSelect's
// placeholder, which the list leaves out, so the ✕ is the way back to it. SlimSelect's ✕
// selects its first option; `deselectToPlaceholder` in slim-select-controller.js points it at
// the placeholder, which a remote result chosen outside the seed displaces (#1495).
describe('SlimSelect blank', () => {
  const expectBlank = (select, main, placeholder) => {
    cy.get(select).should('have.value', '')
    cy.get(main).find('.ss-values .ss-placeholder').should('have.text', placeholder)
    cy.get(main).find('.ss-deselect').should('have.class', 'ss-hide')
  }

  it('empties an include_blank select back to the blank with the ✕', () => {
    cy.visit('/bali/form/slim_select/optional_blank')
    cy.get('select[name="form_record[select]"]').as('select').should('have.value', '2')
    cy.get('#form_record_select_select_div .ss-main').as('main')

    cy.get('@main').find('.ss-deselect').should('not.have.class', 'ss-hide').click()

    expectBlank('@select', '@main', 'None (top level)')
  })

  describe('on a remote select', () => {
    // Waits for the list to close: closing puts the seed back, and that is when SlimSelect
    // moves the chosen result ahead of the placeholder.
    const choose = (term, name, value) => {
      cy.get('@main').click()
      cy.get('.ss-content.ss-open .ss-search input').type(term)
      cy.wait('@remoteSearch')
      cy.contains('.ss-content.ss-open .ss-optgroup .ss-option', name).click()

      cy.get('@select').should('have.value', value)
      cy.get('.ss-content.ss-open').should('not.exist')
    }
    const clear = () => cy.get('@main').find('.ss-deselect').should('not.have.class', 'ss-hide').click()

    beforeEach(() => {
      cy.intercept('GET', '/users.json*').as('remoteSearch')
      cy.visit('/bali/form/slim_select/remote_with_blank')
      cy.get('select[name="form_record[name]"]').as('select').should('have.value', '')
      cy.get('.ss-main').as('main')
    })

    it('empties back to the blank after choosing a result the seed lacks', () => {
      choose('peter', 'Peter Jackson', '10')
      clear()

      expectBlank('@select', '@main', 'Anyone')
    })

    it('empties back to the blank after a second search', () => {
      choose('peter', 'Peter Jackson', '10')
      choose('jane', 'Jane Smith', '4')
      clear()

      expectBlank('@select', '@main', 'Anyone')
    })

    // While a search is listed, the blank is only there if the search handed it back: missing,
    // SlimSelect gives the ✕ an empty placeholder of its own.
    it('empties back to the blank with a search still listed', () => {
      cy.get('@main').click()
      cy.contains('.ss-content.ss-open .ss-option', 'Option 2').click()
      cy.get('@select').should('have.value', '2')
      cy.get('@main').click()
      cy.get('.ss-content.ss-open .ss-search input').type('jane')
      cy.wait('@remoteSearch')
      cy.contains('.ss-content.ss-open .ss-optgroup .ss-option', 'Jane Smith')

      clear()

      expectBlank('@select', '@main', 'Anyone')
      cy.get('.ss-content.ss-open').should('not.exist')
      cy.get('@select').find('option[value=""]').should('have.length', 1)
    })
  })
})
