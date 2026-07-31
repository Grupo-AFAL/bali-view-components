describe('BulkActionsController', () => {
  const container = '.data-table-component'
  const toolbar = '[data-bulk-actions-target="toolbar"]'
  const bar = '[data-bulk-actions-target="actionsContainer"]'
  const counter = '[data-bulk-actions-target="selectedCount"]'
  const selectAll = '[data-bulk-actions-target="selectAll"]'
  const rows = `${container} tbody tr[data-bulk-actions-target="item"]`

  beforeEach(() => {
    cy.visit('/bali/data_table/with_bulk_actions')
  })

  it('swaps the toolbar for the contextual bar when a row is selected', () => {
    cy.get(toolbar).should('not.have.class', 'hidden')
    cy.get(bar).should('have.class', 'hidden')

    cy.get(rows).first().find('input[type="checkbox"]').check()

    cy.get(toolbar).should('have.class', 'hidden')
    cy.get(bar).should('not.have.class', 'hidden')
    cy.get(counter).should('have.text', '1')
    cy.get('[data-bulk-actions-target="selectedLabelOne"]').should('not.have.class', 'hidden')
    cy.get('[data-bulk-actions-target="selectedLabelOther"]').should('have.class', 'hidden')
  })

  it('injects the selected ids into every action form', () => {
    cy.get(rows).eq(0).find('input[type="checkbox"]').check()
    cy.get(rows).eq(1).find('input[type="checkbox"]').check()

    cy.get(counter).should('have.text', '2')
    cy.get('[data-bulk-actions-target="selectedLabelOther"]').should('not.have.class', 'hidden')
    cy.get(`${bar} input[name="selected_ids"]`).first().should(($input) => {
      expect(JSON.parse($input.val())).to.have.length(2)
    })
  })

  it('selects and deselects the whole page from the header checkbox', () => {
    cy.get(rows).then(($rows) => {
      const total = $rows.length

      cy.get(selectAll).check()
      cy.get(counter).should('have.text', String(total))
      cy.get(`${rows}.selected`).should('have.length', total)

      cy.get(selectAll).uncheck()
      cy.get(counter).should('have.text', '0')
      cy.get(toolbar).should('not.have.class', 'hidden')
    })
  })

  it('leaves the header checkbox indeterminate on a partial selection', () => {
    cy.get(rows).first().find('input[type="checkbox"]').check()

    // La propiedad, no el atributo: `indeterminate` no existe como atributo HTML.
    cy.get(selectAll).should(($input) => {
      expect($input[0].indeterminate).to.eq(true)
      expect($input[0].checked).to.eq(false)
    })
  })

  it('restores the toolbar when the selection is cleared', () => {
    cy.get(rows).first().find('input[type="checkbox"]').check()
    cy.get(`${bar} button[data-action="bulk-actions#clear"]`).click()

    cy.get(counter).should('have.text', '0')
    cy.get(`${rows}.selected`).should('have.length', 0)
    cy.get(toolbar).should('not.have.class', 'hidden')
    cy.get(bar).should('have.class', 'hidden')
  })

  it('selects a row on double click and keeps its checkbox in sync', () => {
    cy.get(rows).first().find('td').eq(1).dblclick()
    cy.get(counter).should('have.text', '1')
    cy.get(rows).first().find('input[type="checkbox"]').should('be.checked')

    cy.get(rows).first().find('td').eq(1).dblclick()
    cy.get(counter).should('have.text', '0')
    cy.get(rows).first().find('input[type="checkbox"]').should('not.be.checked')
  })
})
