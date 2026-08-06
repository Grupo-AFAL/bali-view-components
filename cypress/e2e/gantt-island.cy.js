// Isla Gantt (#705): monta GanttFlow por el circuito COMPLETO de un host —
// startIslandLoader('gantt') en el bundle principal lee las metas de
// react_island_meta_tags, inyecta la entry gantt-island.js, registerIsland
// registra sobre window.Stimulus con guard, y GanttController (subclase de
// ReactIslandController) monta React Flow con values→props.
//
// Se mide visibilidad/estructura, no textContent suelto (memoria del repo).
// El preview editable pega contra los endpoints de referencia del dummy
// (Admin::Projects::SchedulesController) sobre el proyecto seedeado: las
// ediciones PERSISTEN y el drag de vuelta solo compensa en parte (el snap no
// es exactamente simetrico) — `bin/rails db:seed` restaura las fechas. Las
// aserciones no dependen de fechas absolutas por eso mismo.

const instancias = (win) =>
  win.Stimulus.controllers.filter((c) => c.identifier === 'gantt')

const anchoDe = ($el) => $el[0].getBoundingClientRect().width

// Arrastra un nodo de React Flow `dx` px en horizontal. d3-drag escucha
// mousedown en el nodo y sigue mousemove/mouseup en la window del AUT — los
// eventos sinteticos necesitan `view: win` (d3 hace select(event.view)) o
// nodrag revienta con "Cannot read properties of undefined".
const arrastrarNodo = (selector, dx) => {
  cy.window().then((win) => {
    cy.get(selector).first().then(($node) => {
      const rect = $node[0].getBoundingClientRect()
      const startX = rect.left + rect.width / 2
      const startY = rect.top + rect.height / 2
      cy.wrap($node)
        .trigger('mousedown', { button: 0, clientX: startX, clientY: startY, view: win, force: true })
      cy.document()
        .trigger('mousemove', { clientX: startX + dx / 2, clientY: startY, view: win, force: true })
      cy.document()
        .trigger('mousemove', { clientX: startX + dx, clientY: startY, view: win, force: true })
      cy.document()
        .trigger('mouseup', { clientX: startX + dx, clientY: startY, view: win, force: true })
    })
  })
}

describe('Gantt island', () => {
  it('monta la isla via el loader lazy sobre el Stimulus del host', () => {
    cy.visit('/bali/gantt/island_readonly')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.window().should((win) => expect(instancias(win)).to.have.length(1))

    // Readonly: sin handles de resize (solo existen con editable=true).
    cy.get('.cursor-ew-resize').should('not.exist')
  })

  it('pinta el milestone como diamante y la arista critica con el color de error (D10)', () => {
    cy.visit('/bali/gantt/island_readonly')

    cy.get('[data-milestone]').should('exist')

    // La dependencia 21→40 une dos items criticos → arista .critical. Su
    // stroke computado resuelve var(--color-error) y difiere de una normal.
    cy.get('.react-flow__edge.critical').should('exist')
    cy.get('.react-flow__edge.critical path').first().then(($critical) => {
      const criticalStroke = getComputedStyle($critical[0]).stroke
      cy.get('.react-flow__edge:not(.critical) path').first().should(($normal) => {
        expect(criticalStroke).to.not.equal(getComputedStyle($normal[0]).stroke)
      })
    })
  })

  it('el zoom escribe el param namespaceado gantt_zoom sin navegar y reescala', () => {
    cy.visit('/bali/gantt/island_readonly')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    cy.get('.react-flow__node').first().then(($bar) => {
      const weekWidth = anchoDe($bar)
      // Scoped al grupo de zoom: un contains('Day') suelto matchea el boton
      // oculto "Days" del dropdown de columnas.
      cy.get('[role="group"][aria-label="Zoom"]').contains('button', 'Day').click()
      cy.location('search').should('include', 'gantt_zoom=day')
      // day = 24 px/dia vs week = 8: la misma barra se ensancha 3x.
      cy.get('.react-flow__node').first().should(($after) => {
        expect(anchoDe($after)).to.be.greaterThan(weekWidth * 2)
      })
    })

    // replaceState, no navegacion: la isla sigue montada (1 instancia).
    cy.window().should((win) => expect(instancias(win)).to.have.length(1))
  })

  it('colapsar un grupo esconde sus barras y color-by cambia el pintado', () => {
    cy.visit('/bali/gantt/island_readonly')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    // Color-by: el fondo inline del cuerpo de la primera barra cambia de
    // formula (el wrapper del nodo no lleva background; el cuerpo si).
    cy.get('.react-flow__node').first().find('div[style*="background"]').first().then(($bar) => {
      const statusFill = $bar[0].style.background
      cy.get('[role="group"][aria-label="Color by"]').contains('button', 'Priority').click()
      cy.get('.react-flow__node').first().find('div[style*="background"]').first().should(($after) => {
        expect($after[0].style.background).to.not.equal(statusFill)
      })
    })

    // Colapso: el caret del primer grupo de la tabla reduce las filas/barras.
    cy.get('.react-flow__node').then(($nodes) => {
      const before = $nodes.length
      cy.get('button[aria-expanded="true"]').first().click()
      cy.get('.react-flow__node').should(($after) => {
        expect($after.length).to.be.lessThan(before)
      })
    })
  })

  it('arrastrar una barra postea el PATCH del contrato y reconcilia', () => {
    cy.intercept('PATCH', '/admin/projects/*/schedule').as('patch')
    cy.visit('/bali/gantt/island')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)
    // Editable: los handles de resize existen (aparecen en hover).
    cy.get('.cursor-ew-resize').should('exist')

    // Ida: +10 dias en zoom week (8 px/dia).
    arrastrarNodo('.react-flow__node', 80)
    cy.wait('@patch').then(({ request, response }) => {
      expect(request.body.item.id).to.be.a('number')
      expect(request.body.item.starts_on).to.match(/^\d{4}-\d{2}-\d{2}$/)
      expect(request.body.item.duration_days).to.be.greaterThan(0)
      expect(response.statusCode).to.equal(200)
      // Reconcile: el documento COMPLETO, no un parche.
      expect(response.body).to.have.all.keys('groups', 'items', 'dependencies', 'critical_ids')
    })
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.get('.alert-error').should('not.exist')

    // Vuelta: restaura las fechas del seed (misma distancia, snap identico).
    arrastrarNodo('.react-flow__node', -80)
    cy.wait('@patch').its('response.statusCode').should('equal', 200)
    cy.get('.alert-error').should('not.exist')
  })
})
