// El marcador "Recordar filtros" gobierna la búsqueda rápida pero no cubría los filtros
// simplificados, y una vista guardada sobre EL MISMO listado sí los restauraba: dos
// mecanismos del mismo componente con dos definiciones de "el estado de los filtros" (#852).
//
// Vive contra `/admin/studios` y no contra un preview de Lookbook porque el defecto necesita
// el round-trip completo: la cookie de persistencia, el form GET de SimpleFilters que manda
// TODOS sus controles, y la caché del server entre dos requests. Nada de eso existe en un
// preview.
describe('La persistencia de filtros cubre los filtros simplificados', () => {
  // El dummy vive arriba del path de previews al que apunta `baseUrl`, así que el origen se
  // deriva de él. Un `http://localhost:3001` literal ignora CYPRESS_BASE_URL y prueba en
  // silencio el server de otro checkout.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const listing = `${appOrigin}/admin/studios`

  // El total sale del pie de la paginación, no de contar `<tr>`: la tabla pagina de a 10, así
  // que las filas no distinguen 9 de 34.
  const total = () =>
    cy.contains(/of \d+ studios/i).invoke('text').then(text => Number(/of (\d+) studios/i.exec(text)[1]))

  // El submit navega, así que hay que esperar la URL nueva antes de leer nada: sin eso
  // `total()` lee el DOM viejo una sola vez y no reintenta. Se afirma sobre el nombre
  // codificado (`q%5Bsize_eq%5D`) porque es lo que un GET pone en la barra.
  const submitFiltersAndWaitFor = param => {
    cy.get('form[data-turbo-frame="_top"] button[type="submit"]').first().click()
    cy.location('search').should('include', param)
  }

  beforeEach(() => {
    cy.viewport(1600, 1000)
    // Lo que el marcador de la toolbar escribe. Cypress limpia las cookies entre tests, y con
    // ellas la sesión — que es lo que namespacea la caché (ver ApplicationController#filter_context).
    cy.setCookie('bali_persist_admin_studios', '1')
  })

  it('devuelve el filtro simplificado al volver con la URL limpia, aplicado y pintado', () => {
    cy.visit(listing)

    total().then(everything => {
      cy.get('input[name="q[size_eq]"][value="large"]').check()
      submitFiltersAndWaitFor('q%5Bsize_eq%5D=large')

      total().then(filtered => {
        expect(filtered, 'el filtro tiene que recortar').to.be.lessThan(everything)

        // La vuelta al listado: sin `q` en la URL, la caché es la única fuente del estado.
        cy.visit(listing)
        cy.location('search').should('eq', '')

        // Las dos mitades: que RECORTE y que se VEA. Afirmar solo el radio pasaría con un
        // control pintado sobre un listado sin filtrar.
        total().should('eq', filtered)
        cy.get('input[name="q[size_eq]"][value="large"]').should('be.checked')
      })
    })
  })

  it('no lo restaura con el marcador apagado', () => {
    // El arreglo amplía lo que el marcador CUBRE; no puede cambiar lo que el marcador significa.
    cy.visit(listing)
    total().then(everything => {
      cy.get('input[name="q[size_eq]"][value="large"]').check()
      submitFiltersAndWaitFor('q%5Bsize_eq%5D=large')
      total().should('be.lessThan', everything)

      cy.clearCookie('bali_persist_admin_studios')
      cy.visit(listing)
      total().should('eq', everything)
      cy.get('input[name="q[size_eq]"][value="large"]').should('not.be.checked')
    })
  })

  it('deja que la URL le gane a la caché: un enlace compartido no arrastra una búsqueda guardada', () => {
    // Como `has_filter_params` no contaba los simplificados, una URL que solo pedía uno caía
    // en el branch de RESTAURAR y la caché le ganaba a la URL: el mismo enlace rendía distinto
    // según una cookie de quien lo abría (9 filas contra 10, medido sobre `?q[country_eq]=USA`).
    cy.visit(`${listing}?q[name_cont]=a`)
    cy.get('input[name="q[name_cont]"]').should('have.value', 'a')

    cy.visit(`${listing}?q[country_eq]=USA`)
    // La prueba directa: la búsqueda vieja se veía en la caja, y nadie la escribió en la URL.
    cy.get('input[name="q[name_cont]"]').should('have.value', '')

    total().then(withPersistence => {
      cy.clearCookie('bali_persist_admin_studios')
      cy.visit(`${listing}?q[country_eq]=USA`)
      total().should('eq', withPersistence)
    })
  })

  it('limpiar la búsqueda no se lleva los filtros simplificados', () => {
    // `clearSearch` navega descartando TODOS los `q[...]`, así que si el estado guardado no
    // los conserva —o los conserva y no los aplica— los selects se vacían con la búsqueda.
    cy.visit(`${listing}?q[size_eq]=large&q[name_cont]=a`)

    total().then(searchedAndFiltered => {
      cy.get('input[name="q[name_cont]"]').should('have.value', 'a')

      cy.visit(`${listing}?clear_search=true`)
      cy.get('input[name="q[name_cont]"]').should('have.value', '')
      cy.get('input[name="q[size_eq]"][value="large"]').should('be.checked')
      total().should('be.greaterThan', searchedAndFiltered)
    })
  })
})
