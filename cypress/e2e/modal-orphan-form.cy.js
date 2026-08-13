// #984 — `submit_group(..., drawer: true)` en página completa: el `drawer#submit` del
// botón y el `drawer#close` del Cancel caen en el controller huérfano que AppLayout monta
// en `<main>` (`data-controller="modal drawer"`, sin targets). Las guardias devuelven los
// eventos al browser ANTES del preventDefault: el submit degrada al submit normal del form
// y el Cancel navega. Antes de la guardia esto era el botón muerto con spinner eterno, el
// 422 comido por `_replaceContent` y el Cancel tragado.
//
// El preview manda por GET a su propia URL, así que la prueba de que el submit salió por
// el camino del browser es el query string — mismo criterio que simple-filters-auto-submit.
const PREVIEW = '/bali/app_layout/orphan_drawer_form'

describe('drawer: true huérfano en página completa (#984)', () => {
  it('el submit degrada al submit normal del form y el botón no queda muerto', () => {
    cy.visit(PREVIEW)
    cy.get('form button[type="submit"]').click()

    cy.location('search').should('include', 'probe=1')
    cy.get('form button[type="submit"]').should('not.be.disabled')
    cy.get('form button[type="submit"] .loading-spinner').should('not.exist')
  })

  it('el Cancel navega en vez de tragarse el click', () => {
    cy.visit(PREVIEW)
    cy.contains('a', /cancel/i).click()

    cy.location('search').should('include', 'cancelled=1')
  })
})
