// #1452 — a remote search that fails says so where its results would be, and reads it out.
// Cypress fails a test on an unhandled rejection, so every failing search below also guards the
// console.
const search = term => {
  cy.get('.ss-main').click()
  cy.get('.ss-content.ss-open .ss-search input').type(term)
}
const list = () => cy.get('.ss-content.ss-open .ss-list')

// The message in the list and in SlimSelect's live region (`.ss-status`), which still says
// "Searching..." if the message is only painted.
const expectMessage = text => {
  cy.get('.ss-content.ss-open').should($content => {
    expect($content.find('.ss-searching'), 'searching row').to.have.length(0)
    expect($content.find('.ss-list .ss-error').text(), 'in the list').to.equal(text)
    expect($content.find('.ss-status').text(), 'read out').to.equal(text)
  })
}

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

      expectMessage('Search failed. Please try again.')
    })
  })

  // Read while the request is built, so it throws before there is a request to fail. The user
  // reads "Search failed"; the developer needs the cause, in the console.
  it('says the search failed when a dependent field\'s selector is not valid', () => {
    cy.visit('/bali/form/slim_select/remote_dependent', {
      onBeforeLoad: win => cy.spy(win.console, 'error').as('consoleError')
    })
    cy.get('[data-controller="slim-select"]')
      .invoke('attr', 'data-slim-select-ajax-param-selectors-value', '{"family":"[name=a[b]]"}')
    search('jo')

    expectMessage('Search failed. Please try again.')
    cy.get('@consoleError').should('have.been.calledWithMatch', '[SlimSelect] Remote search failed:',
      Cypress.sinon.match.has('message', Cypress.sinon.match(/is not a valid selector/)))
  })

  it('says the search failed in the page language', () => {
    cy.intercept('GET', '/users.json*', { statusCode: 500 }).as('remoteSearch')
    cy.visit('/bali/form/slim_select/remote?locale=es')
    search('jo')
    cy.wait('@remoteSearch')

    expectMessage('No se pudo completar la búsqueda. Intenta de nuevo.')
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

    expectMessage('Start typing to get results...')
    cy.wait(500)
    cy.get('@remoteSearch.all').should('have.length', 0)
  })
})
