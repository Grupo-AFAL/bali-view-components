// A single `bulk-actions` for N listings: each select-all checks its own and the counter is
// still one, the total. What the component rules out —one instance per group— would give N
// counters and no total, and nesting them would leave the outer bar blind to the rows.
describe('BulkActionsController — selection by subgroup', () => {
  const counter = '[data-bulk-actions-target="selectedCount"]'
  const tables = '.table-component'
  const rows = 'tbody tr[data-bulk-actions-target="item"]'
  const groupHeader = 'tr.bali-table-group-row'
  const selectAll = 'thead input[type="checkbox"]'

  describe('several tables under a single bar', () => {
    beforeEach(() => {
      cy.visit('/bali/table/selectable_by_group')
    })

    it('scopes each table select-all to its own rows', () => {
      cy.get(tables).eq(0).find(selectAll).check()

      cy.get(tables).eq(0).find(`${rows}.selected`).should('have.length', 3)
      cy.get(tables).eq(1).find(`${rows}.selected`).should('have.length', 0)
      cy.get(counter).should('have.text', '3')
    })

    it('adds both tables up in the SAME counter', () => {
      cy.get(tables).eq(0).find(selectAll).check()
      cy.get(tables).eq(1).find(selectAll).check()

      cy.get(counter).should('have.text', '7')
      cy.get(`${rows}.selected`).should('have.length', 7)
    })

    it('scopes a group select-all to its own run', () => {
      cy.get(tables).eq(1).find(groupHeader).first().find('input').check()

      cy.get(tables).eq(1).find(`${rows}.selected`).should('have.length', 2)
      cy.get(tables).eq(0).find(`${rows}.selected`).should('have.length', 0)
      cy.get(counter).should('have.text', '2')
    })

    // The row carries both ids —its table's and its group's—, so the one above still reaches
    // it: without that, the header of a grouped table would check nothing.
    it('lets the table header reach its groups', () => {
      cy.get(tables).eq(1).find(selectAll).check()

      cy.get(tables).eq(1).find(`${rows}.selected`).should('have.length', 4)
      cy.get(tables).eq(1).find(`${groupHeader} input`).each(($input) => {
        expect($input[0].checked).to.eq(true)
      })
    })

    it('leaves the header indeterminate when only one group is complete', () => {
      cy.get(tables).eq(1).find(groupHeader).first().find('input').check()

      cy.get(tables).eq(1).find(selectAll).should(($input) => {
        // The property, not the attribute: `indeterminate` does not exist as an HTML attribute.
        expect($input[0].indeterminate).to.eq(true)
        expect($input[0].checked).to.eq(false)
      })
      cy.get(tables).eq(1).find(`${groupHeader} input`).eq(1).should(($input) => {
        expect($input[0].indeterminate).to.eq(false)
        expect($input[0].checked).to.eq(false)
      })
    })

    it('takes the group state back when a single row is unchecked', () => {
      cy.get(tables).eq(1).find(groupHeader).first().find('input').check()
      cy.get(tables).eq(1).find(rows).first().find('input[type="checkbox"]').uncheck()

      cy.get(tables).eq(1).find(`${groupHeader} input`).first().should(($input) => {
        expect($input[0].checked).to.eq(false)
        expect($input[0].indeterminate).to.eq(true)
      })
      cy.get(counter).should('have.text', '1')
    })
  })

  describe('rows outside the selection', () => {
    beforeEach(() => {
      cy.visit('/bali/table/partially_selectable')
    })

    it('does not let the select-all reach the rows declared out', () => {
      cy.get('tbody tr').should('have.length', 5)
      cy.get(rows).should('have.length', 3)

      cy.get(selectAll).check()

      cy.get(`${rows}.selected`).should('have.length', 3)
      cy.get(counter).should('have.text', '3')
      cy.get(selectAll).should(($input) => {
        expect($input[0].checked).to.eq(true)
        expect($input[0].indeterminate).to.eq(false)
      })
    })

    // The empty cell is what holds the alignment: without it, the columns of that row shift
    // by one position.
    it('keeps the empty selection cell on the rows that do not take part', () => {
      cy.get('tbody tr').each(($row) => {
        expect($row.find('td')).to.have.length(4)
      })
      cy.get('tbody tr').not(rows).find('input[type="checkbox"]').should('have.length', 0)
    })
  })
})
