// #1452 — a remote search that fails says so where its results would be. Before, the
// controller's promise never settled: SlimSelect's "Searching..." stayed up for good and the
// rejection went out unhandled. Cypress fails a test on an unhandled rejection, so every
// failing search below also guards the console.
const search = term => {
  cy.get('.ss-main').click()
  cy.get('.ss-content.ss-open .ss-search input').type(term)
}
const list = () => cy.get('.ss-content.ss-open .ss-list')

describe('SlimSelect remote search', () => {
  const failures = {
    // What `head :forbidden` answers a `.json` request with.
    'a 403 with an empty body': { statusCode: 403, headers: { 'content-type': 'application/json' }, body: '' },
    'a 500': { statusCode: 500, headers: { 'content-type': 'text/html' }, body: '<h1>Server error</h1>' },
    'a network error': { forceNetworkError: true },
    // It parses, so only the status says the search failed: read as a result, it is "No results".
    'a 403 whose body is a list': { statusCode: 403, body: [] }
  }

  Object.entries(failures).forEach(([name, response]) => {
    it(`says the search failed on ${name}`, () => {
      cy.intercept('GET', '/users.json*', response).as('remoteSearch')
      cy.visit('/bali/form/slim_select/remote')
      search('jo')
      cy.wait('@remoteSearch')

      list().should($list => {
        expect($list.find('.ss-searching'), 'searching row').to.have.length(0)
        expect($list.find('.ss-error').text()).to.equal('Search failed. Please try again.')
      })
    })
  })

  it('says the search failed in the page language', () => {
    cy.intercept('GET', '/users.json*', { statusCode: 500 }).as('remoteSearch')
    cy.visit('/bali/form/slim_select/remote?locale=es')
    search('jo')
    cy.wait('@remoteSearch')

    list().find('.ss-error').should('have.text', 'No se pudo completar la búsqueda. Intenta de nuevo.')
  })

  it('lists what a search that succeeds finds', () => {
    cy.intercept('GET', '/users.json*').as('remoteSearch')
    cy.visit('/bali/form/slim_select/remote')
    search('jo')
    cy.wait('@remoteSearch')

    // The group, not the whole list: SlimSelect keeps the selected option above it.
    list().should($list => {
      expect($list.find('.ss-error'), 'error row').to.have.length(0)
      expect($list.find('.ss-optgroup .ss-option').toArray().map(option => option.textContent.trim()))
        .to.deep.equal(['John Doe', 'John Smith', 'John Wayne', 'Peter Johnson'])
    })
  })

  it('asks for a second character without searching', () => {
    cy.intercept('GET', '/users.json*').as('remoteSearch')
    cy.visit('/bali/form/slim_select/remote')
    search('j')

    list().find('.ss-error').should('have.text', 'Start typing to get results...')
    cy.wait(500)
    cy.get('@remoteSearch.all').should('have.length', 0)
  })
})
