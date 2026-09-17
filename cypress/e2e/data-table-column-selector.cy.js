// El selector de columnas esconde celdas POR ÍNDICE, y dos filas de `Bali::Table` no llevan
// una celda por columna: la banda de grupo (un `td` con `colspan`) y el estado vacío (otro que
// cubre la tabla entera). Antes el índice las alcanzaba y borraba la celda equivocada — la
// banda con el botón de plegado adentro, o el mensaje de «sin resultados» (#1144).
describe('DataTable column selector sobre una tabla agrupada', () => {
  const grouped = '#grouped-columns'
  const empty = '#empty-columns'
  const band = 'tr.bali-table-group-row'
  const trigger = `${band} button[data-table-groups-target="trigger"]`
  const rows = 'tbody tr[data-table-groups-target="row"]'

  // `force`: el panel del dropdown lo abre el `:focus-within` de daisyUI, así que la casilla
  // no es accionable con el menú cerrado. Lo que importa acá es el `change` que dispara.
  const hideFirstColumn = (listing) =>
    cy.get(`${listing} [data-controller~="column-selector"] input[data-column-index="0"]`)
      .uncheck({ force: true })

  beforeEach(() => {
    cy.visit('/bali/data_table/with_column_selector')
  })

  it('esconde la columna sin llevarse las bandas de grupo', () => {
    cy.get(`${grouped} ${band}`).should('have.length', 3)

    hideFirstColumn(grouped)

    // La columna se fue de verdad: encabezado y celda de una fila de datos.
    cy.get(`${grouped} thead th`).eq(0).should('not.be.visible')
    cy.get(`${grouped} ${rows}`).first().find('td').eq(0).should('not.be.visible')

    // La banda no: su celda abarca las cuatro columnas, así que el índice 0 no la nombra.
    cy.get(`${grouped} ${band}`).should('have.length', 3).each(($row) => {
      cy.wrap($row).find('td').should('be.visible')
    })
    cy.get(`${grouped} ${trigger}`).should('have.length', 3).and('be.visible')
  })

  // El caso grave: con la banda plegada, su botón es lo ÚNICO que puede volver a mostrar esas
  // filas. Esconderlo las dejaba inalcanzables hasta recargar la página.
  it('deja desplegable la banda que nace plegada', () => {
    hideFirstColumn(grouped)

    cy.get(`${grouped} ${trigger}[aria-expanded="false"]`).should('have.length', 1).then(($trigger) => {
      const groupRows = `${grouped} ${rows}[data-group-token="${$trigger.attr('data-group-token')}"]`

      cy.get(groupRows).should('have.length', 2).and('not.be.visible')

      cy.wrap($trigger).click()
      cy.wrap($trigger).should('have.attr', 'aria-expanded', 'true')
      cy.get(groupRows).should('be.visible')
    })
  })

  // El segundo listado de la preview no tiene filas. Su `<tr>` no lleva clase propia, así que
  // una guarda por fila (`tr:not(.bali-table-group-row)`) lo habría dejado roto igual.
  it('no borra el estado vacío de un listado sin resultados', () => {
    hideFirstColumn(empty)

    cy.get(`${empty} thead th`).eq(0).should('not.be.visible')
    cy.get(`${empty} td.empty-table`).should('be.visible').and('not.have.text', '')
  })
})
