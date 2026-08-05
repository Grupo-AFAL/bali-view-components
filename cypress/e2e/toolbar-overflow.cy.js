// El movimiento de nodos solo es observable en un navegador: Minitest ve el HTML servido,
// que es siempre el layout expandido.
//
// 1440 y no 1280 como viewport "ancho": el colapso ya no lo decide el breakpoint sino cuánto
// ancho NECESITA la fila (medido ~1180px en este preview), y a 1280 el margen quedaba en
// ~70px — menos de lo que puede moverse el mismo texto renderizado con otras fuentes en CI.
// Un ancho holgado prueba lo que la prueba quiere probar: expandido es expandido.
describe('DataTable toolbar overflow', () => {
  const menu = '[data-toolbar-overflow-target="menu"]'
  const overflow = '[data-toolbar-overflow-target="overflow"]'
  const leftGroup = '[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="left"]'
  const memoryGroup = '[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="memory"]'
  const separator = '[data-toolbar-overflow-target="separator"]'
  const columnsItem = '[data-toolbar-overflow-priority="35"]'
  const filtersItem = '[data-toolbar-overflow-priority="70"]'
  const viewSwitchItem = '[data-toolbar-overflow-priority="50"]'
  const groupByItem = '[data-toolbar-overflow-priority="40"]'

  it('moves the secondary controls into the ⋯ menu and back, never duplicating them', () => {
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(columnsItem).should('have.length', 1)
    cy.get(`${menu} ${columnsItem}`).should('not.exist')
    cy.get(overflow).should('have.class', 'hidden')

    cy.viewport(375, 667)

    cy.get(`${menu} ${columnsItem}`).should('have.length', 1)
    cy.get(`${menu} ${groupByItem}`).should('have.length', 1)
    // MOVIDO, no duplicado: dos column selectors serían dos controladores sobre una tabla.
    cy.get(columnsItem).should('have.length', 1)
    cy.get('[data-controller~="column-selector"]').should('have.length', 1)
    cy.get(overflow).should('not.have.class', 'hidden')

    // Búsqueda/filtros y el view switch se quedan en la fila: el switch se ENCOGE.
    cy.get(`${menu} ${filtersItem}`).should('not.exist')
    cy.get(`${menu} ${viewSwitchItem}`).should('not.exist')

    cy.viewport(1440, 800)

    cy.get(`${menu} ${columnsItem}`).should('not.exist')
    cy.get(columnsItem).should('have.length', 1)
    cy.get('[data-controller~="column-selector"]').should('have.length', 1)
    cy.get(overflow).should('have.class', 'hidden')
  })

  it('restores the toolbar ordered by priority after a round trip', () => {
    // `expand()` reordena en vez de recordar la posición original: eso es lo que hace al
    // controlador stateless frente a un reconnect de Turbo. Es también la única prueba real
    // del orden de la fila: el HTML servido se ve bien aunque el navegador lo reordene mal.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')
    cy.viewport(1440, 800)

    const sortedDescending = (selector) =>
      cy.get(`${selector} > [data-toolbar-overflow-target="item"]`).then(($items) => {
        const priorities = [...$items].map((el) => Number(el.dataset.toolbarOverflowPriority))
        expect(priorities).to.deep.equal([...priorities].sort((a, b) => b - a))
      })

    // Búsqueda/filtros · agrupar · columnas
    sortedDescending(leftGroup)
    // Vistas guardadas · marcador de persistencia
    sortedDescending(memoryGroup)
  })

  it('hides the separator when the overflow empties one of its sides, and brings it back', () => {
    // La barrita AFIRMA algo sobre sus vecinos: con el grupo de memoria adentro del ⋯ queda
    // marcando una frontera contra nada.
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(separator).should('be.visible')

    cy.viewport(375, 667)

    cy.get(separator).should('not.be.visible')
    cy.get(memoryGroup).should('not.be.visible')

    cy.viewport(1440, 800)

    cy.get(separator).should('be.visible')
    cy.get(memoryGroup).should('be.visible')
  })

  it('never moves the separator into the ⋯', () => {
    // No es un `item`: `collapsibleItems` no la puede ver, así que no puede viajar al menú
    // ni duplicarse.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')

    cy.get(`${menu} ${separator}`).should('not.exist')
    cy.get(separator).should('have.length', 1)
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
    cy.viewport(1440, 800)
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
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    cy.get(`${filtersItem} button[data-action*="toggleDropdown"]`).first().focus()
    cy.viewport(375, 667)

    cy.focused().should('exist')
    cy.document().its('activeElement.tagName').should('not.equal', 'BODY')
  })

  it('keeps keyboard focus when the breakpoint is crossed the OTHER way', () => {
    // El espejo del caso de arriba, y el que faltaba: angosto, el ⋯ es la única forma de
    // llegar a lo colapsado, así que ahí es donde está parado el usuario. Al ensanchar el ⋯
    // se esconde — y no es un `item`, así que no entraba en la restauración de foco.
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/complete')

    // El ⋯ ES un dropdown Y CONTIENE dropdowns: angosto, el overflow le mete adentro Columnas
    // y Vistas, que traen su propio trigger. El descendiente pelado matcheaba los tres y
    // `cy.focus()` no acepta más de un elemento. El del ⋯ es el que NO vive dentro del menú.
    cy.get(`${overflow} [data-dropdown-target="trigger"]`)
      .not(`${menu} [data-dropdown-target="trigger"]`)
      .focus()
    cy.focused().should('have.attr', 'aria-label')

    cy.viewport(1440, 800)

    cy.get(overflow).should('have.class', 'hidden')
    cy.document().its('activeElement.tagName').should('not.equal', 'BODY')
    // Aterriza en un control de la fila, no en cualquier lado del documento.
    cy.focused().closest('[data-toolbar-overflow-target="item"]').should('have.length', 1)
  })

  it('does not render the ⋯ when there is nothing to collapse', () => {
    cy.viewport(375, 667)
    cy.visit('/bali/data_table/default')

    cy.get(filtersItem).should('exist')
    cy.get(overflow).should('not.exist')
  })
})

// La válvula del ⋯ se evaluaba SOLO al montar y al cambiar el ancho del contenedor, y ninguno
// de los dos cubre el caso real: los controles crecen DESPUÉS del primer layout. SlimSelect
// reemplaza su `<select>` por un widget más ancho, flatpickr monta el suyo, una fuente termina
// de cargar — y la fila se desborda sin que nada vuelva a medir.
//
// No se puede provocar con `cy.viewport()`: eso cambia el ancho disponible, que es justo la
// señal que el controlador ya escuchaba. Lo que se ensancha acá es un CONTROL, con el viewport
// quieto — la misma forma que tiene el caso real.
describe('DataTable toolbar overflow when a control grows after mount', () => {
  const menu = '[data-toolbar-overflow-target="menu"]'
  const overflow = '[data-toolbar-overflow-target="overflow"]'
  const filtersItem = '[data-toolbar-overflow-priority="70"]'

  it('collapses into the ⋯ when a control widens with the viewport unchanged', () => {
    cy.viewport(1440, 800)
    cy.visit('/bali/data_table/complete')

    // Punto de partida: la fila entra entera y el ⋯ está guardado.
    cy.get(overflow).should('have.class', 'hidden')
    cy.get(menu).children().should('have.length', 0)

    // Un control se ensancha por su cuenta, como haría SlimSelect al montarse.
    cy.get(filtersItem).then(($item) => {
      $item[0].style.minWidth = `${$item[0].getBoundingClientRect().width + 600}px`
    })

    cy.get(overflow).should('not.have.class', 'hidden')
    cy.get(menu).children().should('have.length.greaterThan', 0)

    // Y vuelve solo cuando el control recupera su tamaño.
    cy.get(filtersItem).then(($item) => { $item[0].style.minWidth = '' })

    cy.get(overflow).should('have.class', 'hidden')
    cy.get(menu).children().should('have.length', 0)
  })
})
