// Los presets de periodo de un filtro `date_range` (#725): el select manda un TOKEN por el
// mismo param que el rango explícito, y "Personalizado…" revela el flatpickr.
//
// Vive contra `/admin/studios` y no contra un preview de Lookbook porque lo que hay que
// probar es el round-trip: el token tiene que salir en el request, recortar el listado en el
// server y volver pintado en el select. Un preview renderiza el widget pero no consulta nada.
describe('Presets de periodo en un filtro de rango de fechas', () => {
  // El dummy vive arriba del path de previews al que apunta `baseUrl`, así que el origen se
  // deriva de él: un `http://localhost:3001` literal ignora CYPRESS_BASE_URL y prueba en
  // silencio el server de otro checkout.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const listing = `${appOrigin}/admin/studios`

  const periodSelect = () => cy.get('select[data-time-period-field-target="select"]')
  const hiddenField = () => cy.get('input[type="hidden"][name="q[created_at]"]')

  // Se afirma sobre el REQUEST y no sobre `location.search`. El submit es un GET de Turbo,
  // que trae la página por fetch y actualiza la barra de direcciones después: leer la URL
  // mide cuándo la escribió Turbo, no si el filtro viajó. El request es el dato.
  const submitAndCaptureRequest = () => {
    cy.intercept('GET', '/admin/studios*').as('filtered')
    cy.get('form[data-turbo-frame="_top"] button[type="submit"]').first().click()
    return cy.wait('@filtered').its('request.url')
  }

  beforeEach(() => {
    cy.viewport(1600, 1000)
    cy.visit(listing)
  })

  it('manda el token en el mismo param del rango y lo devuelve elegido', () => {
    periodSelect().select('this_month')
    // El controller escribe el hidden en cuanto cambia el select — eso es lo único que el
    // form manda.
    hiddenField().should('have.value', 'this_month')

    submitAndCaptureRequest().should('include', 'q%5Bcreated_at%5D=this_month')

    // La otra mitad: que el token vuelva PINTADO, no que solo haya viajado.
    periodSelect().should('have.value', 'this_month')
    hiddenField().should('have.value', 'this_month')
  })

  it('el token recorta de verdad: un periodo sin registros vacía el listado', () => {
    // El seed crea los studios hoy, así que "este mes" los toma a todos y no distingue un
    // filtro aplicado de uno ignorado. Un rango viejo sí: si el `where` no corriera, la
    // tabla seguiría llena.
    cy.get('tbody tr').should('have.length.greaterThan', 1)

    cy.visit(`${listing}?q[created_at]=2001-01-01 to 2001-12-31`)
    cy.contains(/no results/i).should('exist')
    cy.get('tbody tr').should('have.length', 1) // la fila del empty state
  })

  it('esconde el flatpickr hasta que se elige "Personalizado…"', () => {
    // En reposo el picker no está, y el `hidden` viaja en el HTML del server: no es el JS
    // el que lo esconde una interacción tarde.
    cy.get('.flatpickr').should('not.be.visible')

    periodSelect().select('custom')
    cy.get('.flatpickr').should('be.visible')

    // Y al volver a un preset se esconde otra vez.
    periodSelect().select('today')
    cy.get('.flatpickr').should('not.be.visible')
    hiddenField().should('have.value', 'today')
  })

  it('vuelve en "Personalizado…" con el rango puesto cuando el filtro no es un token', () => {
    cy.visit(`${listing}?q[created_at]=2020-01-01 to 2035-12-31`)

    periodSelect().should('have.value', 'custom')
    cy.get('.flatpickr').should('be.visible')
    hiddenField().should('have.value', '2020-01-01 to 2035-12-31')
  })

  it('el select y el picker no mandan params propios: el hidden es el único con name', () => {
    // Dos controles con el mismo `name` mandarían `q[created_at]` dos veces y el server se
    // quedaría con el último, que no es necesariamente el que se ve.
    cy.get('[data-controller="time-period-field"]')
      .find('[name="q[created_at]"]')
      .should('have.length', 1)
      .and('have.attr', 'type', 'hidden')

    periodSelect().select('this_week')
    submitAndCaptureRequest().then(url => {
      expect(url.match(/created_at/g), 'el param viaja UNA vez').to.have.length(1)
      expect(url).to.include('q%5Bcreated_at%5D=this_week')
    })
  })
})
