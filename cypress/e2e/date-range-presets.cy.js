// Period presets on a `date_range` filter (#725): the select sends a TOKEN through the same
// param as the explicit range, and "Custom…" reveals the flatpickr.
//
// It runs against `/admin/studios` and not against a Lookbook preview because what has to be
// tested is the round-trip: the token has to go out in the request, narrow the listing on the
// server and come back selected in the select. A preview renders the widget but queries nothing.
describe('Period presets on a date range filter', () => {
  // The dummy lives above the preview path `baseUrl` points at, so the origin is derived from
  // it: a literal `http://localhost:3001` ignores CYPRESS_BASE_URL and silently tests another
  // checkout's server.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const listing = `${appOrigin}/admin/studios`

  const periodSelect = () => cy.get('select[data-time-period-field-target="select"]')
  const hiddenField = () => cy.get('input[type="hidden"][name="q[created_at]"]')

  // The assertion is on the REQUEST and not on `location.search`. The submit is a Turbo GET,
  // which fetches the page and updates the address bar afterwards: reading the URL measures
  // when Turbo wrote it, not whether the filter travelled. The request is the evidence.
  const submitAndCaptureRequest = () => {
    cy.intercept('GET', '/admin/studios*').as('filtered')
    cy.get('form[data-turbo-frame="_top"] button[type="submit"]').first().click()
    return cy.wait('@filtered').its('request.url')
  }

  beforeEach(() => {
    cy.viewport(1600, 1000)
    cy.visit(listing)
  })

  it('sends the token in the same param as the range and gives it back selected', () => {
    periodSelect().select('this_month')
    // The controller writes the hidden as soon as the select changes — that is the only thing
    // the form submits.
    hiddenField().should('have.value', 'this_month')

    submitAndCaptureRequest().should('include', 'q%5Bcreated_at%5D=this_month')

    // The other half: that the token comes back SELECTED, not just that it travelled.
    periodSelect().should('have.value', 'this_month')
    hiddenField().should('have.value', 'this_month')
  })

  it('the token really narrows: a period with no records empties the listing', () => {
    // The seed creates the studios today, so "this month" takes them all and does not tell an
    // applied filter from an ignored one. An old range does: if the `where` did not run, the
    // table would still be full.
    cy.get('tbody tr').should('have.length.greaterThan', 1)

    cy.visit(`${listing}?q[created_at]=2001-01-01 to 2001-12-31`)
    cy.contains(/no results/i).should('exist')
    cy.get('tbody tr').should('have.length', 1) // the empty state row
  })

  it('hides the flatpickr until "Custom…" is chosen', () => {
    // At rest the picker is not there, and the `hidden` travels in the server HTML: it is not
    // the JS that hides it one interaction late.
    cy.get('.flatpickr').should('not.be.visible')

    periodSelect().select('custom')
    cy.get('.flatpickr').should('be.visible')

    periodSelect().select('today')
    cy.get('.flatpickr').should('not.be.visible')
    hiddenField().should('have.value', 'today')
  })

  it('comes back on "Custom…" with the range filled in when the filter is not a token', () => {
    cy.visit(`${listing}?q[created_at]=2020-01-01 to 2035-12-31`)

    periodSelect().should('have.value', 'custom')
    cy.get('.flatpickr').should('be.visible')
    hiddenField().should('have.value', '2020-01-01 to 2035-12-31')
  })

  it('the select and the picker send no params of their own: only the hidden has a name', () => {
    // Two controls with the same `name` would send `q[created_at]` twice and the server would
    // keep the last one, which is not necessarily the one on screen.
    cy.get('[data-controller="time-period-field"]')
      .find('[name="q[created_at]"]')
      .should('have.length', 1)
      .and('have.attr', 'type', 'hidden')

    periodSelect().select('this_week')
    submitAndCaptureRequest().then(url => {
      expect(url.match(/created_at/g), 'the param travels ONCE').to.have.length(1)
      expect(url).to.include('q%5Bcreated_at%5D=this_week')
    })
  })
})
