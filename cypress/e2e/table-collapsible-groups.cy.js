// `Bali::Table` collapsible groups: the state lives in the DOM —`aria-expanded` on the
// button, `hidden` on the rows— and the controller applies it on connect. What the server
// NEVER does is hide a row: without JS everything stays visible.
describe('TableGroupsController — collapsible groups', () => {
  const table = '#portfolio'
  const selectableTable = '#portfolio-selectable'
  const band = 'tr.bali-table-group-row'
  const trigger = `${band} button[data-table-groups-target="trigger"]`
  const rows = 'tbody tr[data-table-groups-target="row"]'
  const counter = '[data-bulk-actions-target="selectedCount"]'

  const rowsOf = (scope, token) => cy.get(scope).find(`${rows}[data-group-token="${token}"]`)

  beforeEach(() => {
    cy.visit('/bali/table/collapsible_groups')
  })

  it('collapses and expands the band rows when its button is pressed', () => {
    cy.get(table).find(trigger).first().then(($trigger) => {
      const token = $trigger.attr('data-group-token')

      rowsOf(table, token).should('have.length', 2).and('be.visible')

      cy.wrap($trigger).click()
      cy.wrap($trigger).should('have.attr', 'aria-expanded', 'false')
      rowsOf(table, token).should('not.be.visible')

      cy.wrap($trigger).click()
      cy.wrap($trigger).should('have.attr', 'aria-expanded', 'true')
      rowsOf(table, token).should('be.visible')
    })
  })

  // The server marks the button and nothing else; the controller hides the rows on connect.
  it('the band the server marked is born collapsed, with no `hidden` in the served HTML', () => {
    cy.request('/bali/table/collapsible_groups').its('body').should('not.match', /<tr[^>]*\shidden/)

    cy.get(table).find(`${trigger}[aria-expanded="false"]`).should('have.length', 2).each(($trigger) => {
      rowsOf(table, $trigger.attr('data-group-token')).should('not.be.visible')
    })
    cy.get(table).find(`${trigger}[aria-expanded="true"]`).each(($trigger) => {
      rowsOf(table, $trigger.attr('data-group-token')).should('be.visible')
    })
  })

  it('lists in aria-controls exactly the rows it collapses', () => {
    cy.get(table).find(trigger).first().then(($trigger) => {
      const ids = $trigger.attr('aria-controls').split(' ')
      const token = $trigger.attr('data-group-token')

      expect(ids).to.have.length(2)
      rowsOf(table, token).each(($row, index) => {
        expect($row.attr('id')).to.eq(ids[index])
      })
    })
  })

  // The group checkbox lives outside the button and the selection controller does not look
  // at visibility: checking a collapsed band counts its rows all the same.
  it('lets the group select-all check the rows even while they are collapsed', () => {
    cy.get(selectableTable).find(`${trigger}[aria-expanded="false"]`).should('have.length', 5)

    cy.get(selectableTable).find(band).first().find('input[type="checkbox"]').check()

    cy.get(selectableTable).find(`${rows}.selected`).should('have.length', 2)
    cy.get(counter).should('have.text', '2')

    cy.get(selectableTable).find(trigger).first().click()
    cy.get(selectableTable).find(`${rows}.selected`).should('have.length', 2).and('be.visible')
  })
})
