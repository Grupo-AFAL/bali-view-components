// El movimiento de nodos solo es observable en un navegador: Minitest ve el HTML servido,
// que es siempre el layout expandido.
describe('DataTable toolbar overflow', () => {
  const menu = '[data-toolbar-overflow-target="menu"]'
  const overflow = '[data-toolbar-overflow-target="overflow"]'
  const rightGroup = '[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="right"]'
  const exportItem = '[data-toolbar-overflow-priority="10"]'
  const columnsItem = '[data-toolbar-overflow-priority="20"]'
  const filtersItem = '[data-toolbar-overflow-priority="70"]'
  const viewSwitchItem = '[data-toolbar-overflow-priority="50"]'
  const groupByItem = '[data-toolbar-overflow-priority="30"]'

  it('moves the secondary controls into the ⋯ menu and back, never duplicating them', () => {
    cy.viewport(1280, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(columnsItem).should('have.length', 1)
    cy.get(`${menu} ${columnsItem}`).should('not.exist')
    cy.get(overflow).should('have.class', 'hidden')

    cy.viewport(375, 667)

    cy.get(`${menu} ${columnsItem}`).should('have.length', 1)
    cy.get(`${menu} ${exportItem}`).should('have.length.greaterThan', 0)
    // MOVIDO, no duplicado: dos column selectors serían dos controladores sobre una tabla.
    cy.get(columnsItem).should('have.length', 1)
    cy.get('[data-controller~="column-selector"]').should('have.length', 1)
    cy.get(overflow).should('not.have.class', 'hidden')

    // Búsqueda/filtros y el view switch se quedan en la fila: el switch se ENCOGE.
    cy.get(`${menu} ${filtersItem}`).should('not.exist')
    cy.get(`${menu} ${viewSwitchItem}`).should('not.exist')

    cy.viewport(1280, 800)

    cy.get(`${menu} ${columnsItem}`).should('not.exist')
    cy.get(columnsItem).should('have.length', 1)
    cy.get('[data-controller~="column-selector"]').should('have.length', 1)
    cy.get(overflow).should('have.class', 'hidden')
  })

  it('restores the toolbar ordered by priority after a round trip', () => {
    // `expand()` reordena en vez de recordar la posición original: eso es lo que hace al
    // controlador stateless frente a un reconnect de Turbo.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')
    cy.viewport(1280, 800)

    cy.get(`${rightGroup} > [data-toolbar-overflow-target="item"]`).then(($items) => {
      const priorities = [...$items].map((el) => Number(el.dataset.toolbarOverflowPriority))
      expect(priorities).to.deep.equal([...priorities].sort((a, b) => b - a))
    })
  })

  it('keeps the column selector working after being moved', () => {
    // La prueba real de que `connect()` es idempotente: moverlo dispara disconnect+connect.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')

    // Hijo directo: adentro del ⋯ hay más triggers con role="button" (los controles que
    // acaban de mudarse ahí).
    cy.get(`${overflow} > .dropdown > [role="button"]`).click()
    cy.get(`${menu} [data-controller~="column-selector"] input[data-column-index="2"]`)
      .uncheck({ force: true })

    cy.get('.data-table-component table thead th').eq(2).should('not.be.visible')
  })

  it('closes an open dropdown before folding it into the ⋯', () => {
    // `.dropdown-open` SOBREVIVE al movimiento: sin cerrarlo antes, el control aterriza
    // abierto dentro del menú. Solo se llega por teclado — los demás dropdowns de la
    // toolbar abren por :focus-within de daisyUI y no marcan la clase.
    cy.viewport(1280, 800)
    cy.visit('/bali/data_table/complete')

    // `force`: daisyUI le pone pointer-events:none al trigger de un dropdown abierto (el
    // :focus-within ya lo abrió), y un keydown no necesita accionabilidad de mouse.
    cy.get(`${groupByItem} [data-dropdown-target="trigger"]`)
      .focus()
      .trigger('keydown', { key: 'ArrowDown', force: true })
    cy.get(`${groupByItem} .dropdown-open`).should('have.length', 1)

    cy.viewport(375, 667)

    cy.get(`${menu} ${groupByItem}`).should('have.length', 1)
    cy.get(`${menu} .dropdown-open`).should('not.exist')
  })

  it('keeps keyboard focus on the toolbar when the breakpoint is crossed', () => {
    // Un zoom al 400% deja el viewport en 320px CSS: cruzar el umbral no puede costarle al
    // usuario de teclado su posición. `closeOpenDropdowns` hace blur y el colapso mueve el
    // nodo, así que sin restaurar el foco cae al <body>.
    cy.viewport(1280, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(`${filtersItem} button[data-action*="toggleDropdown"]`).first().focus()
    cy.viewport(375, 667)

    cy.focused().should('exist')
    cy.document().its('activeElement.tagName').should('not.equal', 'BODY')
  })

  it('does not render the ⋯ when there is nothing to collapse', () => {
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/default')

    cy.get(filtersItem).should('exist')
    cy.get(overflow).should('not.exist')
  })
})
