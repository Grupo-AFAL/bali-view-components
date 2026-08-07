// Infinite scroll for the structured SplitView listing. The preview renders page
// one and points the sentinel at the dummy's `/split-view`, so every fetch here is
// a real request against a real paginated index — the same URL one page further
// on, which is the whole claim of fetch-and-extract.
//
// 20 movies, 5 per page: four pages, and the fourth is the end of the list.
describe('SplitView structured list', () => {
  const scroller = () => cy.get('[data-split-view-list-target="scroller"]')
  const rows = () => cy.get('.split-view-item')
  const scrollToBottom = () => scroller().scrollTo('bottom', { ensureScrollable: false })

  context('progressive enhancement', () => {
    beforeEach(() => cy.visit('/bali/split_view/structured_list'))

    // The controls are in the markup and the controller removes them, rather than
    // the other way round — that is what makes the no-JS case the default.
    //
    // `hidden` and not Cypress's `be.visible`: the sentinel sits below the fold of
    // a scroll container, and Cypress calls anything clipped that way invisible.
    // The attribute is the mechanism, so it is also the honest thing to assert —
    // with the computed display checked alongside, because an author `display`
    // beats the attribute and that is a bug this component already had once.
    it('hides the pagination controls and shows the sentinel once connected', () => {
      cy.get('[data-split-view-list-target="pagination"]').should('have.attr', 'hidden')
      cy.get('[data-split-view-list-target="pagination"]').should('not.be.visible')

      cy.get('[data-split-view-list-target="sentinel"]').should('not.have.attr', 'hidden')
      cy.get('[data-split-view-list-target="sentinel"]')
        .should('have.css', 'display')
        .and('not.eq', 'none')
      cy.get('[data-split-view-list-target="loader"]').should('not.have.attr', 'hidden')
      cy.get('[data-split-view-list-target="end"]').should('have.attr', 'hidden')
    })

    // Server-rendered, so it is what a reader without JavaScript is left with.
    it('renders real pagination controls in the markup', () => {
      cy.get('[data-split-view-list-target="pagination"] a').should('have.length.greaterThan', 0)
    })
  })

  context('appending pages', () => {
    beforeEach(() => cy.visit('/bali/split_view/structured_list'))

    it('appends the next page when the sentinel comes into view', () => {
      rows().should('have.length', 5)
      scrollToBottom()
      rows().should('have.length', 10)
    })

    it('keeps going to the end of the list and then says so', () => {
      rows().should('have.length', 5)
      // Four pages of five. Each scroll lands the sentinel again.
      scrollToBottom()
      rows().should('have.length', 10)
      scrollToBottom()
      rows().should('have.length', 15)
      scrollToBottom()
      rows().should('have.length', 20)

      cy.get('[data-split-view-list-target="end"]').should('not.have.attr', 'hidden')
      cy.get('[data-split-view-list-target="loader"]').should('have.attr', 'hidden')

      // Nothing more is fetched once the server stops offering a next page.
      scrollToBottom()
      cy.wait(500)
      rows().should('have.length', 20)
    })

    it('gives appended rows the same wiring as the server-rendered ones', () => {
      scrollToBottom()
      rows().should('have.length', 10)

      rows().eq(7).should('have.attr', 'data-turbo-frame', 'split-view-detail')
      rows().eq(7).should('have.attr', 'data-split-view-target', 'row')
      rows().eq(7).should('have.attr', 'data-action', 'click->split-view#select')
    })

    it('selects an appended row like any other', () => {
      scrollToBottom()
      rows().should('have.length', 10)

      rows().eq(8).click()
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      rows().eq(8).should('have.attr', 'aria-current', 'true')
      cy.get('.split-view-item[aria-current="true"]').should('have.length', 1)
    })

    // The appended page is rendered by a URL that knows nothing about a click made
    // after the first render, so its markup can carry a stale selection. The
    // `rowTargetConnected` hook re-derives it; without that, two rows light up.
    it('does not let an appended page bring back a stale selection', () => {
      rows().eq(1).click()
      rows().eq(1).should('have.attr', 'aria-current', 'true')

      scrollToBottom()
      rows().should('have.length', 10)

      cy.get('.split-view-item[aria-current="true"]').should('have.length', 1)
      rows().eq(1).should('have.attr', 'aria-current', 'true')
    })
  })

  context('deep link to a record beyond the first page', () => {
    beforeEach(() => cy.visit('/bali/split_view/deep_link_beyond_the_first_page'))

    // The documented corner: the server finds the record against the whole table,
    // so the detail is there immediately — but its row simply is not on screen.
    it('shows the detail while its row is still unloaded', () => {
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      cy.get('.split-view-item[aria-current="true"]').should('not.exist')
    })

    it('highlights the row once its page has been appended', () => {
      cy.get('.split-view-item[aria-current="true"]').should('not.exist')
      scrollToBottom()
      rows().should('have.length', 10)
      cy.get('.split-view-item[aria-current="true"]').should('have.length', 1)
    })
  })

  // Against the dummy's own page rather than a preview: this is about Turbo's
  // history, and the preview is not a location the app routes to.
  context('across a back navigation', () => {
    const app = path =>
      `${Cypress.config('baseUrl').replace(/\/lookbook\/preview\/?$/, '')}${path}`

    // Measured, because the obvious guess is the wrong one: Turbo caches the
    // snapshot of the page it is leaving, and by then the appended rows are part
    // of it. Going back does NOT reset the list to page one.
    it('keeps the pages already appended, and does not append them twice', () => {
      cy.visit(app('/split-view'))
      rows().should('have.length', 5)
      scrollToBottom()
      rows().should('have.length', 10)

      rows().eq(7).click()
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      cy.location('search').should('contain', 'selected=')

      cy.go('back')
      cy.location('search').should('eq', '')
      rows().should('have.length', 10)

      // The restored markup carries the next page the controller had reached, not
      // the one the server first rendered — Stimulus reflects a changed value back
      // to its attribute, so the snapshot is honest about where the list got to.
      // If it were not, the next scroll would re-append a page already on screen.
      scrollToBottom()
      rows().should('have.length', 15)
      cy.get('.split-view-item').then(($rows) => {
        const ids = [...$rows].map(row => row.id)
        expect(new Set(ids).size, 'row ids are unique').to.eq(ids.length)
      })
    })
  })

  // Filtering is an ordinary GET, which is the whole design: nothing in the
  // component resets the infinite scroll, because a full-page navigation already
  // does. These run against the dummy's page, where the filter is a real
  // SimpleFilters row over a real Ransack scope.
  context('filtering the list', () => {
    const app = path =>
      `${Cypress.config('baseUrl').replace(/\/lookbook\/preview\/?$/, '')}${path}`

    beforeEach(() => cy.visit(app('/split-view')))

    it('puts the filter band above the rows and outside the scroll area', () => {
      cy.get('[data-testid="list-filters"]').should('be.visible')
      cy.get('[data-split-view-list-target="scroller"] [data-testid="list-filters"]')
        .should('not.exist')
    })

    // The pill submits on click (`auto_submit: true`), which is a full-page
    // navigation and therefore renders page one — no reset to perform.
    it('filters on a pill click and comes back on page one', () => {
      rows().should('have.length', 5)
      scrollToBottom()
      rows().should('have.length', 10)

      // The pill IS the radio: daisyUI styles `input[type=radio].btn` and takes its
      // text from `aria-label`, so there is no <label> element to click.
      cy.get('[data-testid="list-filters"] input[name="q[status_eq]"][aria-label^="Done"]')
        .check()
      cy.location('search').should('contain', 'status_eq')
      rows().should('have.length', 5)
      cy.get('[data-testid="list-count"]').should('have.text', '17')
    })

    // The sentinel fetches the URL the server handed it, so the filter travels
    // without the controller knowing anything about filters. Measured, because
    // "it should inherit them" is exactly the kind of thing that silently does not.
    it('carries the filter into the pages the sentinel fetches', () => {
      cy.visit(app('/split-view?q%5Bstatus_eq%5D=1'))
      cy.get('[data-testid="list-count"]').should('have.text', '17')
      rows().should('have.length', 5)

      cy.intercept('GET', '/split-view*').as('nextPage')
      scrollToBottom()
      cy.wait('@nextPage').its('request.url').should('include', 'status_eq')
      rows().should('have.length', 10)

      // And the rows that arrived really are the filtered ones: 17 of 20 movies
      // are `done`, so an unfiltered page 2 would overshoot the filtered total.
      scrollToBottom()
      scrollToBottom()
      rows().should('have.length', 17)
      cy.get('[data-split-view-list-target="end"]').should('not.have.attr', 'hidden')
    })

    it('keeps selecting a row while a filter is on', () => {
      cy.visit(app('/split-view?q%5Bstatus_eq%5D=1'))
      rows().eq(2).click()
      cy.get('.split-view-detail [data-testid="detail-title"]').should('be.visible')
      cy.location('search').should('contain', 'selected=')
      rows().eq(2).should('have.attr', 'aria-current', 'true')
    })
  })

  context('when a page fails to load', () => {
    // The other failure shape, and the one a status code does not describe: a
    // perfectly good 200 that is not this listing — a redirect to a login page,
    // or an index that stopped rendering the component. Appending nothing
    // silently would be indistinguishable from reaching the end of the list, so
    // it has to land on the error state like any other failure.
    it('treats a 200 without the list in it as a failure, not as the end', () => {
      cy.visit('/bali/split_view/structured_list')
      cy.intercept('GET', '/split-view*', {
        statusCode: 200,
        body: '<html><body><h1>Please sign in</h1></body></html>'
      }).as('wrongPage')

      scrollToBottom()
      cy.wait('@wrongPage')

      cy.get('[data-split-view-list-target="error"]').should('not.have.attr', 'hidden')
      cy.get('[data-split-view-list-target="end"]').should('have.attr', 'hidden')
      rows().should('have.length', 5)
    })

    it('offers a retry that resumes from the same page', () => {
      cy.visit('/bali/split_view/structured_list')
      // `times: 1` so only the first attempt fails and the retry reaches the real
      // server. Registering a second, pass-through intercept instead does not
      // reliably unstub the first.
      cy.intercept({ method: 'GET', url: '/split-view*', times: 1 },
        { statusCode: 500, body: 'boom' }).as('failed')

      scrollToBottom()
      cy.wait('@failed')
      cy.get('[data-split-view-list-target="error"]').should('not.have.attr', 'hidden')
      cy.get('[data-split-view-list-target="loader"]').should('have.attr', 'hidden')
      rows().should('have.length', 5)

      // The failed attempt left `nextUrl` untouched, so retrying asks for the very
      // page that failed rather than skipping it. `force` because the button lives
      // below the fold of the scroll container and Cypress would scroll to reach
      // it, which fires the observer and confuses what triggered what.
      cy.get('[data-split-view-list-target="error"] button').click({ force: true })
      rows().should('have.length', 10)
      cy.get('[data-split-view-list-target="error"]').should('have.attr', 'hidden')
    })
  })
})
