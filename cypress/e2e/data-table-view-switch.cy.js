// The view switch can only really be tested by navigating: what matters is what survives
// the mode change, and that lives in the query string the server builds.
describe('DataTable view switch', () => {
  const viewSwitch = '.view-switch-component'
  const savedViews = '[data-controller~="saved-views"]'

  it('keeps the filters, the applied saved view and the grouping when the mode changes', () => {
    cy.visit('/bali/data_table/complete?group_by=genre&saved_view=1&q%5Bname_cont%5D=a&page=2')

    cy.get(`${viewSwitch} a[aria-current="page"]`).should('contain.text', 'Table')
    cy.get('table').should('exist')
    cy.get(savedViews).should('contain.text', 'Indie only')

    cy.get(viewSwitch).contains('a', 'Cards').click()

    cy.location('search').should((search) => {
      expect(search).to.include('view=grid')
      expect(search).to.include('group_by=genre')
      expect(search).to.include('saved_view=1')
      expect(search).to.include('name_cont')
      // Switching views goes back to the first page: `page` is the only thing dropped.
      expect(search).to.not.include('page=')
    })

    cy.get('table').should('not.exist')
    cy.get('.card-title').should('have.length.greaterThan', 0)
    cy.get(`${viewSwitch} a[aria-current="page"]`).should('contain.text', 'Cards')
    cy.get(savedViews).should('contain.text', 'Indie only')
  })

  it('renders the third mode, which Bali knows nothing about', () => {
    cy.visit('/bali/data_table/complete')
    cy.get(viewSwitch).contains('a', 'Calendar').click()

    cy.get('.calendar-component').should('exist')
    // The container only proves the generic slot painted something: what proves the mode
    // works are the cells with listing data inside it.
    cy.get('.calendar-component .badge').should('have.length.greaterThan', 0)
    // Asking for a bare `table` will not do: Calendar itself draws the month with a <table>.
    // What has to disappear is the LISTING table, and its unmistakable mark is the header's
    // "select all" checkbox.
    cy.get('thead input[type="checkbox"]').should('not.exist')
    cy.get(`${viewSwitch} a[aria-current="page"]`).should('contain.text', 'Calendar')
  })

  it('falls back to the first declared view when ?view= is unknown', () => {
    // The raw param never reaches the content without going through the declared views:
    // without that gate, a made-up `?view=` left the listing empty.
    cy.visit('/bali/data_table/complete?view=kanban')

    cy.get(`${viewSwitch} a[aria-current="page"]`).should('contain.text', 'Table')
    cy.get('table').should('exist')
  })

  it('keeps the display mode when filters are applied from the cards view', () => {
    // The filter submit rebuilds the URL from `url:`, with no query string: the mode
    // survives because it travels as a hidden field, just like the grouping.
    cy.visit('/bali/data_table/complete?view=grid')

    cy.get('input[type="hidden"][name="view"]').should('have.value', 'grid')
  })
})
