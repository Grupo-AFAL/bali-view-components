// The "Remember filters" toggle governs the quick search but did not cover the simple
// filters, and a saved view over THE SAME listing did restore them: two mechanisms of the
// same component with two definitions of "the filter state" (#852).
//
// It runs against `/admin/studios` and not against a Lookbook preview because the defect
// needs the full round-trip: the persistence cookie, the SimpleFilters GET form that submits
// ALL of its controls, and the server cache between two requests. None of that exists in a
// preview.
describe('Filter persistence covers the simple filters', () => {
  // The dummy lives above the preview path `baseUrl` points at, so the origin is derived from
  // it. A literal `http://localhost:3001` ignores CYPRESS_BASE_URL and silently tests another
  // checkout's server.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const listing = `${appOrigin}/admin/studios`

  // The total comes from the pagination footer, not from counting `<tr>`: the table paginates
  // by 10, so the rows do not tell 9 from 34.
  const total = () =>
    cy.contains(/of \d+ studios/i).invoke('text').then(text => Number(/of (\d+) studios/i.exec(text)[1]))

  // The submit navigates, so the new URL has to be awaited before reading anything: without
  // that, `total()` reads the old DOM once and does not retry. The assertion is on the encoded
  // name (`q%5Bsize_eq%5D`) because that is what a GET puts in the address bar.
  const submitFiltersAndWaitFor = param => {
    cy.get('form[data-turbo-frame="_top"] button[type="submit"]').first().click()
    cy.location('search').should('include', param)
  }

  beforeEach(() => {
    cy.viewport(1600, 1000)
    // What the toolbar toggle writes. Cypress clears the cookies between tests, and with them
    // the session — which is what namespaces the cache (see ApplicationController#filter_context).
    cy.setCookie('bali_persist_admin_studios', '1')
  })

  it('brings the simple filter back on a return to a clean URL, applied and rendered', () => {
    cy.visit(listing)

    total().then(everything => {
      cy.get('input[name="q[size_eq]"][value="large"]').check()
      submitFiltersAndWaitFor('q%5Bsize_eq%5D=large')

      total().then(filtered => {
        expect(filtered, 'the filter has to narrow').to.be.lessThan(everything)

        // Back to the listing: with no `q` in the URL, the cache is the only source of the state.
        cy.visit(listing)
        cy.location('search').should('eq', '')

        // Both halves: that it NARROWS and that it SHOWS. Asserting only the radio would pass
        // with a rendered control over an unfiltered listing.
        total().should('eq', filtered)
        cy.get('input[name="q[size_eq]"][value="large"]').should('be.checked')
      })
    })
  })

  it('does not restore it with the toggle off', () => {
    // The fix widens what the toggle COVERS; it cannot change what the toggle means.
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

  it('lets the URL beat the cache: a shared link does not drag a saved search along', () => {
    // Because `has_filter_params` did not count the simple filters, a URL that asked only for
    // one fell into the RESTORE branch and the cache beat the URL: the same link rendered
    // differently depending on a cookie of whoever opened it (9 rows against 10, measured over
    // `?q[country_eq]=USA`).
    cy.visit(`${listing}?q[name_cont]=a`)
    cy.get('input[name="q[name_cont]"]').should('have.value', 'a')

    cy.visit(`${listing}?q[country_eq]=USA`)
    // The direct proof: the old search showed up in the box, and nobody wrote it into the URL.
    cy.get('input[name="q[name_cont]"]').should('have.value', '')

    total().then(withPersistence => {
      cy.clearCookie('bali_persist_admin_studios')
      cy.visit(`${listing}?q[country_eq]=USA`)
      total().should('eq', withPersistence)
    })
  })

  it('clearing the search does not take the simple filters with it', () => {
    // `clearSearch` navigates discarding ALL the `q[...]`, so if the saved state does not
    // keep them — or keeps them and does not apply them — the selects empty out along
    // with the search.
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
