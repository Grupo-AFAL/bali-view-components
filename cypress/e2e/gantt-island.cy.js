// Isla Gantt (#705): monta GanttFlow por el circuito COMPLETO de un host —
// startIslandLoader('gantt') en el bundle principal lee las metas de
// react_island_meta_tags, inyecta la entry gantt-island.js, registerIsland
// registra sobre window.Stimulus con guard, y GanttController (subclase de
// ReactIslandController) monta React Flow con values→props.
//
// Desde #970 la isla es el unico renderer, asi que estos previews son los del
// componente: `default` (readonly) y `editable`. El swap esqueleto→isla se mide
// aparte, en gantt-swap.cy.js.
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

// Fila de la tabla de un item, por su nombre (el `title` de la fila).
const filaDe = (nombre) => cy.get(`div[title="${nombre}"]`).filter('[class*="cursor-pointer"]')

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
    cy.visit('/bali/gantt/default')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.window().should((win) => expect(instancias(win)).to.have.length(1))

    // Readonly: sin handles de resize (solo existen con editable=true).
    cy.get('.cursor-ew-resize').should('not.exist')
  })

  it('pinta el milestone como diamante y la arista critica con el color de error (D10)', () => {
    cy.visit('/bali/gantt/default')

    // React Flow monta con onlyRenderVisibleElements: a la densidad con la que
    // abre este preview (`:auto` → day, 24 px/dia sobre una ventana de 43 dias)
    // el milestone cae fuera del viewport de Cypress y no existe como nodo. En
    // "month" la ventana entera entra y se puede medir.
    cy.get('[role="group"][aria-label="Zoom"]').contains('button', 'Month').click()

    // Primero se comprueba que la ventana ENTERA esta dentro del viewport, y el
    // numero sale del propio documento en vez de una constante: si sample_data
    // crece hasta no caber ni a densidad month, el fallo dice eso y no "D10
    // roto", que es adonde manda un `[data-milestone]` que no matchea.
    cy.get('[data-controller="gantt"]').then(($mount) => {
      const conFechas = JSON.parse($mount.attr('data-gantt-data-value'))
        .items.filter((item) => item.starts_on).length

      cy.get('.react-flow__node').should(($nodos) => {
        expect($nodos.length, 'nodos visibles a densidad month: si son menos que los items con ' +
          'fechas, el dataset del preview crecio y el culling se esta comiendo la parte derecha')
          .to.be.at.least(conFechas)
      })
    })

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
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    // El preview abre en "day": es el zoom que el servidor resolvio de `:auto`
    // contra la ventana y le paso a la isla en initial-zoom (#970).
    cy.get('[data-controller="gantt"]').should('have.attr', 'data-gantt-initial-zoom-value', 'day')

    cy.get('.react-flow__node').first().then(($bar) => {
      const dayWidth = anchoDe($bar)
      // Scoped al grupo de zoom: un contains('Week') suelto matchea el boton
      // oculto del dropdown de columnas.
      cy.get('[role="group"][aria-label="Zoom"]').contains('button', 'Week').click()
      cy.location('search').should('include', 'gantt_zoom=week')
      // day = 24 px/dia vs week = 8: la misma barra se encoge 3x.
      cy.get('.react-flow__node').first().should(($after) => {
        expect(anchoDe($after)).to.be.lessThan(dayWidth / 2)
      })
    })

    // replaceState, no navegacion: la isla sigue montada (1 instancia).
    cy.window().should((win) => expect(instancias(win)).to.have.length(1))
  })

  it('colapsar un grupo esconde sus barras y color-by cambia el pintado', () => {
    cy.visit('/bali/gantt/default')
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
    cy.visit('/bali/gantt/editable')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)
    // Editable: los handles de resize existen (aparecen en hover).
    cy.get('.cursor-ew-resize').should('exist')

    // Las ediciones PERSISTEN en la DB del dummy y este spec corre una y otra
    // vez contra la misma. Se guarda el estado del item para devolverlo por el
    // mismo endpoint del contrato al final.
    //
    // Antes la vuelta se hacia con un segundo drag de la misma distancia, y NO
    // funciona: el arrastre de vuelta no es el inverso del de ida (medido: la
    // ida mueve 5 dias, la vuelta 0), asi que la fecha derivaba ~5 dias por
    // corrida hasta que el item pasaba al siguiente y el `cy.wait` del segundo
    // PATCH moria por timeout. En CI nunca se vio porque cada corrida hace
    // `db:schema:load db:seed`; en local aparecia a las pocas repeticiones.
    cy.get('[data-controller="gantt"]').then(($isla) => {
      const items = JSON.parse($isla.attr('data-gantt-data-value')).items
      const id = Number(Cypress.$('.react-flow__node').first().attr('data-id'))
      const item = items.find((i) => Number(i.id) === id)
      cy.wrap({
        // Absoluta: `cy.request` resuelve una relativa contra el baseUrl, que
        // aqui apunta dentro de Lookbook y no al endpoint.
        url: `${window.location.origin}${$isla.attr('data-gantt-patch-url-value')}`,
        id,
        nombre: item.name,
        startsOn: item.starts_on,
        dias: Math.round((Date.parse(item.ends_on) - Date.parse(item.starts_on)) / 86400000) + 1
      }).as('itemArrastrado')
    })

    // La fila del item ARRASTRADO (por su nombre, no por posicion: el orden de
    // las filas depende de las fechas) es el testigo del reconcile — tabla y
    // barras salen del MISMO `rows`, y el 200 del PATCH llega antes de que
    // React reposicione nada.
    cy.get('@itemArrastrado').then(({ nombre }) => {
      filaDe(nombre).invoke('text').then((textoInicial) => {
        arrastrarNodo('.react-flow__node', 80)
        cy.wait('@patch').then(({ request, response }) => {
          expect(request.body.item.id).to.be.a('number')
          expect(request.body.item.starts_on).to.match(/^\d{4}-\d{2}-\d{2}$/)
          expect(request.body.item.duration_days).to.be.greaterThan(0)
          expect(response.statusCode).to.equal(200)
          // Reconcile: el documento COMPLETO, no un parche.
          expect(response.body).to.have.all.keys('groups', 'items', 'dependencies', 'critical_ids')
        })
        filaDe(nombre).should('not.have.text', textoInicial)
        cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
        cy.get('.alert-error').should('not.exist')
      })
    })

    // Restaura por API: determinista, y deja la DB como la encontro.
    cy.get('@itemArrastrado').then(({ url, id, startsOn, dias }) => {
      cy.request('PATCH', url, { item: { id, starts_on: startsOn, duration_days: dias } })
        .its('status')
        .should('equal', 200)
    })
  })
})
