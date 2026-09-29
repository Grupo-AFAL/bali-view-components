// The secondary-actions ⋯ lives in the PageHeader, OUTSIDE the node that a filter
// submit's turbo_stream replaces. Whether the href stays up to date after filtering is
// invisible to Minitest: the served HTML always carries the correct state.
describe('Page export links', () => {
  const exportLink = '[data-export-links-target="link"]'
  const secondaryActions = '[aria-label="More actions"]'
  // The dummy app lives above the Lookbook preview path `baseUrl` points at, so the
  // origin is derived from it rather than written out. A literal
  // `http://localhost:3001` ignores CYPRESS_BASE_URL and quietly tests another
  // checkout's server whenever the suite runs from a git worktree.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  it('carries the active slice from the server render', () => {
    cy.visit('/bali/index_page/complete?group_by=genre&q%5Bname_cont%5D=a&page=2')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('format=csv')
      expect(href).to.include('group_by=genre')
      expect(href).to.include('name_cont')
      // Exporting page 2 on its own is never what "export" means.
      expect(href).to.not.include('page=')
    })
  })

  it('re-syncs the href from the URL, so filtering does not freeze it', () => {
    // `filters#_submit` pushes the new URL to the history BEFORE submitting the form, so
    // by the time the event arrives the URL already describes the new slice. It is
    // dispatched on `documentElement` and bubbling because that is what Turbo does: the
    // controller listens on `document`, and a dispatch on `window` never reaches it — its
    // propagation path is only [window].
    cy.visit('/bali/index_page/complete')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      expect($link.attr('href')).to.not.include('group_by')
    })

    cy.window().then((win) => {
      win.history.pushState({}, '', '?group_by=genre&page=3')
      win.document.documentElement.dispatchEvent(new win.Event('turbo:load', { bubbles: true }))
    })

    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('group_by=genre')
      expect(href).to.include('format=csv')
      expect(href).to.not.include('page=')
    })
  })

  it('follows a real filter submit that answers with a turbo_stream', () => {
    // THE case the controller exists for, and the only one the synthetic event above does
    // not test: the response is a turbo_stream that replaces only the listing, so there is
    // no visit, `turbo:load` does NOT fire and the ⋯ does not reconnect either. It runs
    // against the dummy app because Lookbook previews have no controller that answers
    // `turbo_stream`.
    cy.visit(`${appOrigin}/admin/movies`)

    cy.get('[data-filters-target="searchInput"]').type('Alien')
    cy.get('[data-action*="filters#submitSearch"]').click()

    cy.location('search').should('include', 'name_or_genre_or_studio_name_cont')

    cy.get(secondaryActions).click()
    cy.get(exportLink).first().should(($link) => {
      const href = $link.attr('href')
      expect(href).to.include('format=csv')
      expect(href).to.include('name_or_genre_or_studio_name_cont')
    })
  })

  it('opts the download out of Turbo Drive', () => {
    // A CSV is not a response Turbo Drive can render: the visit stalls halfway instead of
    // triggering the download.
    cy.visit('/bali/index_page/complete')

    cy.get(secondaryActions).click()
    cy.get(exportLink).each(($link) => {
      expect($link.attr('data-turbo')).to.equal('false')
    })
  })
})
