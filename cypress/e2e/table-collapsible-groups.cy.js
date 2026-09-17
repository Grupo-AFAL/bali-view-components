// Grupos plegables de `Bali::Table`: el estado vive en el DOM —`aria-expanded` en el botón,
// `hidden` en las filas— y lo aplica el controlador al conectar. Lo que el servidor NUNCA
// hace es esconder una fila: sin JS todo queda visible.
describe('TableGroupsController — grupos plegables', () => {
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

  it('pliega y despliega las filas de la banda al pulsar su botón', () => {
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

  // El servidor marca el botón y nada más; las filas las esconde el controlador al conectar.
  it('nace plegada la banda que el servidor marcó, sin `hidden` en el HTML servido', () => {
    cy.request('/bali/table/collapsible_groups').its('body').should('not.match', /<tr[^>]*\shidden/)

    cy.get(table).find(`${trigger}[aria-expanded="false"]`).should('have.length', 2).each(($trigger) => {
      rowsOf(table, $trigger.attr('data-group-token')).should('not.be.visible')
    })
    cy.get(table).find(`${trigger}[aria-expanded="true"]`).each(($trigger) => {
      rowsOf(table, $trigger.attr('data-group-token')).should('be.visible')
    })
  })

  it('lista en aria-controls exactamente las filas que pliega', () => {
    cy.get(table).find(trigger).first().then(($trigger) => {
      const ids = $trigger.attr('aria-controls').split(' ')
      const token = $trigger.attr('data-group-token')

      expect(ids).to.have.length(2)
      rowsOf(table, token).each(($row, index) => {
        expect($row.attr('id')).to.eq(ids[index])
      })
    })
  })

  // La casilla del grupo vive fuera del botón y el controlador de selección no mira
  // visibilidad: marcar la banda plegada cuenta sus filas igual.
  it('deja que el seleccionar-todo del grupo marque las filas aunque estén plegadas', () => {
    cy.get(selectableTable).find(`${trigger}[aria-expanded="false"]`).should('have.length', 5)

    cy.get(selectableTable).find(band).first().find('input[type="checkbox"]').check()

    cy.get(selectableTable).find(`${rows}.selected`).should('have.length', 2)
    cy.get(counter).should('have.text', '2')

    cy.get(selectableTable).find(trigger).first().click()
    cy.get(selectableTable).find(`${rows}.selected`).should('have.length', 2).and('be.visible')
  })
})
