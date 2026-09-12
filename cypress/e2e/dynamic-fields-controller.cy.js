// Freezes the contract of dynamic-fields-controller (#715, closes the TODO from
// #155). Runs against the Lookbook previews in
// app/components/bali/form/dynamic_fields/.
//
// The table-mode assertions deliberately read the parsed DOM — `<tr>` inside a
// `<template>`, `<tbody>` as the container — because that is the half Minitest
// cannot check: Nokogiri parses HTML4 and drops both.

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

  // A row the user never saved and a row the server already stores are removed
  // differently, and the marker between them is the `[id]` hidden field
  // `fields_for` emits only for a persisted record.
  context('removing an unsaved row', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/default')
    })

    it('has no id hidden field, which is what makes the rows unsaved', () => {
      cy.get('input[name$="[id]"]').should('not.exist')
    })

    it('deletes the row from the DOM', () => {
      cy.get('.character-fields').should('have.length', 2)

      cy.get('.character-fields').first().contains('button', 'Remove').click()

      cy.get('.character-fields').should('have.length', 1)
    })

    it('leaves nothing of the row behind to submit', () => {
      cy.get('.character-fields').first().find('input[type="text"]')
        .should('have.value', 'John Doe')

      cy.get('.character-fields').first().contains('button', 'Remove').click()

      cy.get('input[value="John Doe"]').should('not.exist')
      cy.get('.destroy-flag').should('have.length', 1)
    })

    it('deletes a row that was just added', () => {
      cy.contains('button', 'Add Character').click()
      cy.get('.character-fields').should('have.length', 3)

      cy.get('.character-fields').last().contains('button', 'Remove').click()

      cy.get('.character-fields').should('have.length', 2)
    })
  })

  context('removing a persisted row', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/persisted')
    })

    // `fields_for` appends the id hidden field after the block it renders, so
    // it is a sibling of the row rather than a child of it. The controller
    // matches it by the row's name prefix for exactly that reason.
    it('renders the id hidden field as a sibling of the row', () => {
      cy.get('[data-dynamic-fields-target="container"]')
        .find('input[name="movie[characters_attributes][0][id]"]')
        .should('have.value', '10')

      cy.get('.character-fields').first()
        .find('input[name$="[id]"]')
        .should('not.exist')
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

    it('keeps the id so the server knows which record to destroy', () => {
      cy.get('.character-fields').first().contains('button', 'Remove').click()

      cy.get('input[name="movie[characters_attributes][0][id]"]')
        .should('have.value', '10')
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

    it('closes the gap in the positions when a row is removed', () => {
      row(1).contains('button', 'Remove').click()

      expectRows([['Alpha', '1'], ['Gamma', '2']])
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

  context('table mode', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/table')
    })

    const rows = () =>
      cy.get('tbody[data-dynamic-fields-target="container"] > tr.character-fields')

    it('puts the container target on the tbody', () => {
      cy.get('table > tbody[data-dynamic-fields-target="container"]').should('exist')
      cy.get('div[data-dynamic-fields-target="container"]').should('not.exist')
    })

    it('keeps the rows inside the tbody as table rows', () => {
      rows().should('have.length', 2)
    })

    // The browser hoists a `<div>` that sits between `<table>` and `<tbody>`
    // out of the table. Rendering the header outside the table to begin with is
    // what keeps the add button and its template where the controller can
    // reach them.
    it('renders the header and its template outside the table', () => {
      cy.get('table template').should('not.exist')
      cy.get('table button[data-dynamic-fields-target="button"]').should('not.exist')
      cy.get('[data-dynamic-fields-target="template"]').should('exist')
    })

    it('survives the parser with a tr inside the template', () => {
      cy.get('[data-dynamic-fields-target="template"]').then($template => {
        expect($template[0].content.querySelector('tr.character-fields')).to.not.equal(null)
      })
    })

    it('appends a cloned row as a tr inside the tbody', () => {
      cy.contains('button', 'Add Character').click()

      rows().should('have.length', 3)
      rows().last().find('td').should('have.length', 3)
      rows().last().find('input[type="text"]')
        .invoke('attr', 'name')
        .should('match', /^movie\[characters_attributes\]\[\d+\]\[name\]$/)
    })

    it('renders the column headers the caller asked for', () => {
      cy.get('table thead th').should('have.length', 3)
      cy.get('table thead th').eq(1).should('have.text', 'Character')
    })

    it('renumbers the visible ordinals after adding and removing', () => {
      const expectOrdinals = expected =>
        cy.get('tbody [data-dynamic-fields-target="ordinal"]').should($cells => {
          expect([...$cells].map(cell => cell.textContent.trim())).to.deep.equal(expected)
        })

      expectOrdinals(['1', '2'])

      cy.contains('button', 'Add Character').click()
      expectOrdinals(['1', '2', '3'])

      rows().eq(0).contains('button', 'Remove').click()
      expectOrdinals(['1', '2'])
    })
  })

  context('array mode', () => {
    beforeEach(() => {
      cy.visit('/bali/form/dynamic_fields/array')
    })

    it('names the inputs with the empty brackets Rails reads as an array', () => {
      cy.get('.step-fields').first()
        .find('input[name="movie[steps][][role]"]')
        .should('have.value', 'Author')
    })

    it('renders one row per value', () => {
      cy.get('.step-fields').should('have.length', 2)
    })

    it('never numbers the rows the way fields_for would', () => {
      cy.get('[name*="steps_attributes"]').should('not.exist')
      cy.get('[name*="movie[steps][0]"]').should('not.exist')
    })

    it('keeps the same name on a cloned row', () => {
      cy.contains('button', 'Add Step').click()

      cy.get('.step-fields').should('have.length', 3)
      cy.get('input[name="movie[steps][][role]"]').should('have.length', 3)
    })

    it('gives the cloned row its own control ids', () => {
      cy.contains('button', 'Add Step').click()

      cy.get('.step-fields').last().find('input[name$="[role]"]')
        .invoke('attr', 'id')
        .should('not.contain', 'new_record')
    })

    it('carries no destroy flag', () => {
      cy.get('.destroy-flag').should('not.exist')
      cy.get('[name*="_destroy"]').should('not.exist')
    })

    it('always deletes a removed row from the DOM', () => {
      cy.get('.step-fields').first().contains('button', 'Remove').click()

      cy.get('.step-fields').should('have.length', 1)
      cy.get('input[value="Author"]').should('not.exist')
    })

    it('renumbers the ordinals after adding and removing', () => {
      const expectOrdinals = expected =>
        cy.get('.step-fields [data-dynamic-fields-target="ordinal"]').should($cells => {
          expect([...$cells].map(cell => cell.textContent.trim())).to.deep.equal(expected)
        })

      expectOrdinals(['1', '2'])

      cy.contains('button', 'Add Step').click()
      expectOrdinals(['1', '2', '3'])

      cy.get('.step-fields').eq(0).contains('button', 'Remove').click()
      expectOrdinals(['1', '2'])
    })
  })
})
