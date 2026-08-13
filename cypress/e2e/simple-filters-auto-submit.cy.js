// #725 PR2 — `auto_submit: true` por filtro: las pills filtran al click, sin pasar por el
// botón Filtrar.
//
// Los submits se cuentan con `cy.intercept` del GET del form y nunca leyendo el DOM: el
// preview manda a su propia URL, así que lo único que distingue "no se mandó" de "se mandó"
// es el query string del request. Una pill marcada no prueba nada — la marca el browser al
// click, antes de que el server conteste.
const PREVIEW = '/bali/data_table/simple_filters/auto_submit'

// Solo un submit lleva query string, así que un `cy.visit(PREVIEW)` pelado no cae acá. Un
// visit CON query sí: cuando la URL de partida trae estado, el espía se arma después.
const spyOnSubmits = () =>
  cy.intercept('GET', '**/simple_filters/auto_submit?*').as('submit')

describe('SimpleFilters con auto_submit', () => {
  beforeEach(() => {
    spyOnSubmits()
    cy.visit(PREVIEW)
    cy.get('form[data-controller="submit-on-change"]').should('exist')
  })

  it('no manda nada al cargar la fila', () => {
    cy.wait(500)

    cy.get('@submit.all').should('have.length', 0)
    cy.location('search').should('eq', '')
  })

  it('filtra al click de una pill de radio, sin tocar Filtrar', () => {
    cy.get('input[type="radio"][value="published"]').check()

    cy.wait('@submit').its('request.url').should('include', 'q%5Bstatus_eq%5D=published')
    cy.get('@submit.all').should('have.length', 1)

    // Hay que esperar la URL nueva antes de mirar el DOM: sin eso se lee la página vieja,
    // donde la pill está marcada porque la marcó el browser y no porque volvió del server.
    cy.location('search').should('include', 'q%5Bstatus_eq%5D=published')
    cy.get('input[type="radio"][value="published"]').should('be.checked')
  })

  it('filtra al click de una pill de toggle', () => {
    cy.get('input[type="checkbox"][value="public"]').check()

    cy.wait('@submit').its('request.url').should('include', 'q%5Bkind_in%5D%5B%5D=public')
    cy.location('search').should('include', 'q%5Bkind_in%5D%5B%5D=public')
    cy.get('input[type="checkbox"][value="public"]').should('be.checked')
  })

  // #996 — el select nativo también auto-envía: su change dispara al cerrar el menú con
  // una selección, que es una elección tan terminada como el click de una pill.
  it('filtra al elegir en el select, sin tocar Filtrar', () => {
    cy.get('select[name="q[genre_eq]"]').select('comedy')

    cy.wait('@submit').its('request.url').should('include', 'q%5Bgenre_eq%5D=comedy')
    cy.location('search').should('include', 'q%5Bgenre_eq%5D=comedy')
    cy.get('select[name="q[genre_eq]"]').should('have.value', 'comedy')
  })

  // El opt-in no se lleva puesto el botón: los filtros que no optaron lo siguen necesitando.
  it('deja el botón Filtrar en su lugar', () => {
    cy.get('form[data-controller="submit-on-change"] button[type="submit"]').should('exist')
  })
})

// La acumulación del grupo multi arranca de una URL que ya trae la primera pill, en vez de
// encadenar dos clicks: entre uno y otro hay una visita de Turbo, y el snapshot cacheado que
// restaura primero se lleva el segundo click a un nodo que está por descartarse.
describe('SimpleFilters con auto_submit, grupo multi', () => {
  it('acumula la segunda pill en vez de reemplazar la primera', () => {
    cy.visit(`${PREVIEW}?q%5Bkind_in%5D%5B%5D=public`)
    cy.get('input[type="checkbox"][value="public"]').should('be.checked')

    // Después del visit, para que el espía no cuente la carga inicial — que acá sí trae query.
    spyOnSubmits()
    cy.get('input[type="checkbox"][value="private"]').check()

    cy.wait('@submit').its('request.url').should('include', 'private')
    cy.location('search').should('include', 'private')
    cy.get('input[type="checkbox"][value="public"]').should('be.checked')
    cy.get('input[type="checkbox"][value="private"]').should('be.checked')
  })
})

describe('SimpleFilters sin auto_submit', () => {
  // El control: la misma fila de pills sin la opción no monta el controller ni cablea nada,
  // que es lo que deja intacta cualquier fila que ya existía.
  it('no monta submit-on-change ni cablea las pills', () => {
    cy.visit('/bali/data_table/simple_filters/toggle_group')

    cy.get('form[data-turbo-frame="_top"]').should('exist')
    cy.get('form[data-controller="submit-on-change"]').should('not.exist')
    cy.get('[data-action*="submit-on-change"]').should('not.exist')
  })
})
