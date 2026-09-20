// #1084 — a slim_select remote search sends, besides the term: a fixed scope
// (`ajax_extra_params`) and one taken from another form field (`ajax_param_selectors`).
//
// The assertions are on the intercepted REQUEST and not on the option list: what this
// change adds is what travels in the query, and a matching list can match by coincidence.
// The preview's narrowing is done by the dummy endpoint with `family`, so the list is
// looked at afterwards as confirmation that the parameter reached its destination.
//
// The controller does not search with fewer than two characters (`ajaxPlaceholder` is what
// shows until then), so every term below has at least two.
const search = term => {
  cy.get('.ss-main').click()
  cy.get('.ss-content .ss-search input').clear().type(term)
}

describe('SlimSelect ajax dependent on another field', () => {
  beforeEach(() => {
    cy.intercept('GET', '/users.json*').as('remoteSearch')
    cy.visit('/bali/form/slim_select/remote_dependent')
  })

  it('sends the fixed params and omits the dependent one while nothing is selected', () => {
    search('jo')

    cy.wait('@remoteSearch').then(({ request }) => {
      expect(request.query.q, 'the term').to.equal('jo')
      expect(request.query.source, 'the fixed param').to.equal('bali')
      expect(request.query, 'no narrowing without a selected field').to.not.have.property('family')
    })
  })

  it('adds the param from the field it depends on and narrows the search', () => {
    cy.get('#user-family').select('Smith')
    search('jo')

    cy.wait('@remoteSearch').its('request.query.family').should('equal', 'Smith')

    // `.ss-optgroup` and not the whole `.ss-list`: SlimSelect keeps the SELECTED option at
    // the very top, outside the group, so the full list includes the one the widget came
    // with. The search results are the ones in the group, the one the controller labels
    // with `resultsText`. And `should` with a callback and not `each`, which does not retry.
    cy.get('.ss-content .ss-list .ss-optgroup .ss-option').should($options => {
      expect($options.length, 'results').to.be.greaterThan(0)
      $options.each((_i, option) => expect(option.textContent.trim()).to.match(/Smith$/))
    })
  })

  // The field is read ON EVERY SEARCH, not on connect: changing it afterwards is the whole
  // use case, and reading it just once is exactly how this would fail silently.
  it('reads the field again when it changes between two searches', () => {
    cy.get('#user-family').select('Smith')
    search('jo')
    cy.wait('@remoteSearch').its('request.query.family').should('equal', 'Smith')

    cy.get('#user-family').select('Doe')
    search('joh')
    cy.wait('@remoteSearch').its('request.query.family').should('equal', 'Doe')
  })

  it('goes back to omitting the param when the field is cleared', () => {
    cy.get('#user-family').select('Smith')
    search('jo')
    cy.wait('@remoteSearch')

    cy.get('#user-family').select('')
    search('joh')

    cy.wait('@remoteSearch').then(({ request }) => {
      expect(request.query).to.not.have.property('family')
      expect(request.query.source).to.equal('bali')
    })
  })
})
