// Freezes the current contract of dynamic-fields-controller (#715 PR1,
// closes the TODO from #155) before any behavior change lands. Runs against
// the Lookbook previews in app/components/bali/form/dynamic_fields/.

describe('DynamicFieldsController', () => {
  context('adding fields', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/default')
    })

    it('renders one row per existing record', () => {
      cy.get('.character-fields').should('have.length', 2)
    })

    it('clones the template into the container', () => {
      cy.contains('button', 'Add Character').click()
      cy.get('.character-fields').should('have.length', 3)

      cy.contains('button', 'Add Character').click()
      cy.get('.character-fields').should('have.length', 4)
    })

    it('replaces the new_record placeholder with a numeric child index', () => {
      cy.contains('button', 'Add Character').click()

      cy.get('.character-fields')
        .last()
        .find('input[type="text"]')
        .invoke('attr', 'name')
        .should('match', /^movie\[characters_attributes\]\[\d+\]\[name\]$/)

      cy.get('[data-dynamic-fields-target="container"] [name*="new_record"]')
        .should('not.exist')
    })

    it('adds the first row to an empty container', () => {
      cy.visit('/bali/form/dynamic_fields/empty')

      cy.get('.character-fields').should('have.length', 0)
      cy.contains('button', 'Add Your First Character').click()
      cy.get('.character-fields').should('have.length', 1)
    })
  })

  context('removing fields', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/default')
    })

    it('hides the row instead of deleting it from the DOM', () => {
      cy.get('.character-fields').first().as('row')

      cy.get('@row').contains('button', 'Remove').click()
      cy.get('@row').should('exist').and('not.be.visible')
      cy.get('.character-fields').should('have.length', 2)
    })

    it('flags the record for destruction', () => {
      cy.get('.character-fields').first().within(() => {
        cy.contains('button', 'Remove').click()
        cy.get('.destroy-flag').should('have.value', 'true')
      })
    })

    it('strips the non-hidden form elements but keeps the hidden ones', () => {
      cy.get('.character-fields').first().within(() => {
        cy.get('input[type="text"]').should('exist')

        cy.contains('button', 'Remove').click()

        cy.get('input[type="text"]').should('not.exist')
        cy.get('input[type="hidden"]').should('exist')
      })
    })
  })

  context('reordering', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/sortable')
    })

    // [name, position] per row, in DOM order
    const expectRows = expected => {
      cy.get('#sortable-characters [data-dynamic-fields-target="container"] .character-fields')
        .should($rows => {
          const actual = [...$rows].map(row => [
            row.querySelector('input[type="text"]').value,
            row.querySelector('[data-position]').value
          ])
          expect(actual).to.deep.equal(expected)
        })
    }

    const row = index => cy.get('.character-fields').eq(index)

    it('renders the rows in order', () => {
      expectRows([['Alpha', '1'], ['Beta', '2'], ['Gamma', '3']])
    })

    it('moveDown swaps the row with the next one and renumbers positions', () => {
      row(0).contains('button', 'Down').click()
      expectRows([['Beta', '1'], ['Alpha', '2'], ['Gamma', '3']])
    })

    it('moveUp swaps the row with the previous one and renumbers positions', () => {
      row(2).contains('button', 'Up').click()
      expectRows([['Alpha', '1'], ['Gamma', '2'], ['Beta', '3']])
    })

    it('moveUp on the first row is a no-op', () => {
      row(0).contains('button', 'Up').click()
      expectRows([['Alpha', '1'], ['Beta', '2'], ['Gamma', '3']])
    })

    it('moveDown on the last row is a no-op', () => {
      row(2).contains('button', 'Down').click()
      expectRows([['Alpha', '1'], ['Beta', '2'], ['Gamma', '3']])
    })

    it('stamps the new size on the added row position input', () => {
      cy.contains('button', 'Add Character').click()

      cy.get('.character-fields').should('have.length', 4)
      cy.get('.character-fields').last().find('[data-position]')
        .should('have.value', '4')
    })
  })

  context('remove duplicates', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/remove_duplicates')
    })

    const addButton = () =>
      cy.get('#genre-picker [data-dynamic-fields-target="button"]')

    it('omits the options already selected in other rows from the cloned template', () => {
      addButton().click()

      cy.get('#genre-picker .genre-fields').should('have.length', 2)
      cy.get('#genre-picker .genre-fields').eq(1).within(() => {
        cy.get('select option').should('have.length', 2)
        cy.get('option[value="action"]').should('not.exist')
      })
    })

    it('disables the add button when every option is in use', () => {
      addButton().click()
      cy.get('#genre-picker .genre-fields').should('have.length', 2)
      addButton().should('not.be.disabled').click()

      cy.get('#genre-picker .genre-fields').should('have.length', 3)
      addButton().should('be.disabled')
    })

    it('disables the add button on connect when already at maximum', () => {
      cy.get('#genre-picker-full [data-dynamic-fields-target="button"]')
        .should('be.disabled')
    })

    it('re-enables the add button when a row is removed', () => {
      addButton().click()
      cy.get('#genre-picker .genre-fields').should('have.length', 2)
      addButton().click()
      addButton().should('be.disabled')

      cy.get('#genre-picker .genre-fields').last()
        .contains('button', 'Remove').click()

      addButton().should('not.be.disabled')
    })
  })
})
