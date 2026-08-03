// El bloque de `SimpleFilters` lleva la etiqueta ARRIBA de cada control, asi que mide el
// doble que cualquier vecino de una linea, y envuelve a dos renglones cuando la fila
// aprieta. Con la toolbar centrada, todo lo que comparte fila con el se alineaba contra el
// CENTRO del bloque en vez de contra su linea de controles: medido en /admin/studios a
// 1900px, el ⋯ a y=226 y el boton Filter —que vive en la ultima linea de ese bloque— a
// y=264, 38px abajo.
//
// La pagina es `/admin/studios` y no un preview porque hacen falta las dos cosas juntas:
// `SimpleFilters` y controles colapsables que llenen el ⋯. El preview
// `data_table/with_simple_filters` tiene lo primero y no lo segundo, asi que ahi el ⋯ ni
// se renderiza. El origen se deriva de `baseUrl` en vez de escribirse: un
// `http://localhost:3001` literal ignora CYPRESS_BASE_URL y prueba en silencio el servidor
// de otro checkout cuando la suite corre desde un worktree.
const appOrigin = new URL(Cypress.config('baseUrl')).origin
const estudios = () => cy.visit(`${appOrigin}/admin/studios`)

const filaFiltros = () => cy.get('.data-table-component form > div').first()
const abajo = el => Math.round(el.getBoundingClientRect().bottom)

describe('DataTable: la fila de la toolbar se alinea por su linea de controles', () => {
  it('apoya el ⋯ en la misma linea que el boton de filtrar', () => {
    cy.viewport(1900, 1000)
    estudios()

    // La valvula tarda: los controles que desbordan la fila crecen DESPUES del primer
    // layout (SlimSelect reemplaza su select, flatpickr monta el suyo), asi que el ⋯ no
    // esta ahi al montar.
    cy.get('[data-toolbar-overflow-target="overflow"]').should('not.have.class', 'hidden')

    cy.get('.data-table-component form button[type="submit"]').first().then($submit => {
      cy.get('[data-toolbar-overflow-target="overflow"] .btn').first().then($puntos => {
        expect(abajo($puntos[0]) - abajo($submit[0]), 'diferencia vertical').to.equal(0)
      })
    })
  })

  // Los 4px de relleno que se quitaron para lograr esa alineacion eran el lugar del anillo
  // de foco del ultimo control: la fila era contenedor de scroll en TODOS los anchos
  // (`overflow-x-auto` sin condicion) y un contenedor de scroll recorta en su caja de
  // relleno. Arriba del breakpoint la fila envuelve y no scrollea nunca, asi que el
  // overflow vuelve a `visible` y no queda nada que recortar.
  it('no convierte la fila en contenedor de scroll donde no scrollea', () => {
    cy.viewport(1900, 1000)
    estudios()

    filaFiltros().should($fila => {
      const cs = window.getComputedStyle($fila[0])
      expect(cs.overflowX, 'sin contenedor de scroll').to.equal('visible')
      expect(cs.overflowY).to.equal('visible')
    })
  })

  // Debajo del breakpoint no cambia nada: ahi la fila SI scrollea en horizontal y el hueco
  // de abajo es el de su barra.
  it('conserva el scroll horizontal de los filtros en un telefono', () => {
    cy.viewport(375, 800)
    estudios()

    filaFiltros().should($fila => {
      const cs = window.getComputedStyle($fila[0])
      expect(cs.overflowX).to.equal('auto')
      expect(parseFloat(cs.paddingBottom), 'el hueco de la barra sigue').to.be.greaterThan(0)
      expect($fila[0].scrollWidth, 'y hay de donde scrollear').to.be.greaterThan(
        $fila[0].clientWidth
      )
    })
  })
})
