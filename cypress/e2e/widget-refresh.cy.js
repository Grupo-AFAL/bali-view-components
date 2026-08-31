// A card that keeps itself current: it asks the server for itself and swaps in
// the turbo-stream that comes back — the same exchange a resize uses, without
// the write.
//
// The interval that ships on `ProjectProgress` is 20s, far too long to wait for
// in a spec, so these drive `refresh()` directly and let the network prove the
// round trip. What is worth testing here is not the timer — `setTimeout` works —
// but the FOUR REASONS A TICK IS SKIPPED, none of which a Ruby test can see.
const appOrigin = new URL(Cypress.config('baseUrl')).origin

describe('a widget refreshes itself', () => {
  const card = (key) => `[data-widget-key="${key}"]`
  const REFRESHING = 'project_progress'
  // A ListBase, so it has row links: real focusable content outside edit mode,
  // which `project_progress` does not have — its only focusable children are the
  // edit chrome, and that is CSS-hidden until you enter edit mode.
  const LIST = 'recent_movies'

  // Reaches the Stimulus controller for one card. `application` is exposed by
  // the dummy app's own bootstrap.
  const controllerFor = (win, key) =>
    win.Stimulus.getControllerForElementAndIdentifier(
      win.document.querySelector(`[data-widget-key="${key}"]`),
      'bali-widget-refresh'
    )

  beforeEach(() => {
    cy.viewport(1400, 1500)
    cy.visit(`${appOrigin}/dashboard_widgets`)
  })

  it('wires the controller onto the widget that asked for it, and no other', () => {
    cy.get(`${card(REFRESHING)}[data-controller~="bali-widget-refresh"]`).should('exist')

    // `overdue_tasks` declares no interval. Every card on this page was handed
    // the same URL, so this proves the URL alone does not start a poll.
    cy.get(`${card('overdue_tasks')}[data-controller~="bali-widget-refresh"]`).should('not.exist')
  })

  it('replaces the card with what the server sends back', () => {
    cy.intercept('GET', '**/dashboard_widgets/refresh*').as('refresh')

    // A marker on the current element. The card is REPLACED rather than patched,
    // so the attribute cannot survive a successful refresh.
    cy.get(card(REFRESHING)).invoke('attr', 'data-stale-marker', 'before')

    cy.window().then((win) => controllerFor(win, REFRESHING).refresh())

    cy.wait('@refresh').its('request.url').should('include', `keys%5B%5D=${REFRESHING}`)
    cy.get(card(REFRESHING)).should('not.have.attr', 'data-stale-marker')
    cy.get(card(REFRESHING)).should('exist')
  })

  // THE GUARD THAT MATTERS MOST. SortableJS is tracking these exact nodes; a
  // stream replacing one mid-drag drops the element under the pointer.
  it('does not refresh while the grid is in edit mode', () => {
    cy.intercept('GET', '**/dashboard_widgets/refresh*', cy.spy().as('refreshCall'))

    cy.visit(`${appOrigin}/dashboard_widgets?editing=1`)
    cy.get('.editing').should('exist')

    cy.window().then((win) => controllerFor(win, REFRESHING).refresh())

    cy.wait(300)
    cy.get('@refreshCall').should('not.have.been.called')
  })

  // A replaced element takes focus to `<body>` with it. The grid restores focus
  // after a RESIZE because the user asked for that one; nobody asked for this,
  // so it defers instead.
  it('does not refresh while focus is inside the card', () => {
    cy.intercept('GET', '**/dashboard_widgets/refresh*', cy.spy().as('refreshCall'))

    cy.get(`${card(LIST)} ul.list a`).first().focus()
    cy.focused().should('exist')

    cy.window().then((win) => controllerFor(win, LIST).refresh())

    cy.wait(300)
    cy.get('@refreshCall').should('not.have.been.called')
  })

  // A dashboard left open in a background tab would otherwise poll for hours.
  // Browsers throttle background timers; they do not stop them.
  it('does not refresh while the tab is hidden', () => {
    cy.intercept('GET', '**/dashboard_widgets/refresh*', cy.spy().as('refreshCall'))

    cy.document().then((doc) => {
      Object.defineProperty(doc, 'hidden', { value: true, configurable: true })
    })
    cy.window().then((win) => controllerFor(win, REFRESHING).refresh())

    cy.wait(300)
    cy.get('@refreshCall').should('not.have.been.called')
  })

  // The size a refresh renders at comes from the stored arrangement, not the
  // widget's default — otherwise every refresh silently un-resizes the card.
  it('comes back at the size the card was resized to', () => {
    // The grid DEBOUNCES its write by 250ms, so navigating straight after the
    // click leaves the resize unsaved and this reads the default back.
    cy.intercept('PATCH', '**/dashboard_widgets/arrange').as('arrange')

    cy.visit(`${appOrigin}/dashboard_widgets?editing=1`)
    cy.get(`${card(REFRESHING)} [data-widget-size="medium"]`).click()
    cy.get(card(REFRESHING)).should('have.attr', 'data-size', 'medium')
    cy.wait('@arrange')

    cy.visit(`${appOrigin}/dashboard_widgets`)
    cy.get(card(REFRESHING)).should('have.attr', 'data-size', 'medium')

    cy.window().then((win) => controllerFor(win, REFRESHING).refresh())

    cy.get(card(REFRESHING)).should('have.attr', 'data-size', 'medium')
  })
})
