// Edit mode writes the `?editing=1` flag into the URL, and THAT MAKES IT TURBO'S
// BUSINESS. Turbo keeps its own history: every entry it creates carries
// `state.turbo = { restorationIdentifier, restorationIndex }`, and its `popstate`
// handler does nothing at all for an entry without that key.
//
// A raw `history.pushState` therefore leaves orphan entries Turbo later refuses
// to restore. Reported from these exact steps — Edit, Done, "View all", Back —
// as "se traga el back: se cambia la URL, pero el contenido de la pagina no."
// Entering and leaving wrote two orphans, so one Back appeared to do nothing.
//
// Against the REAL dashboard rather than the Lookbook preview: the preview's stub
// has no links to other pages, so it cannot navigate away and come back.
const appOrigin = new URL(Cypress.config('baseUrl')).origin

describe('edit mode and browser history', () => {
  const enter = () => cy.get('[data-bali-widget-grid-edit-mode-target="enter"] button').click()
  const leave = () => cy.get('[data-bali-widget-grid-edit-mode-target="leave"] button').click()

  beforeEach(() => {
    cy.viewport(1400, 1500)
    cy.visit(`${appOrigin}/dashboard_widgets`)
  })

  // THE REPORTED BUG, end to end.
  it('restores the dashboard after edit mode and a visit away', () => {
    enter()
    cy.get('.editing').should('exist')
    leave()
    cy.get('.editing').should('not.exist')

    cy.get('[data-widget-key] a').contains(/view all/i).first().click()
    cy.location('pathname').should('not.include', 'dashboard_widgets')

    cy.go('back')

    // The URL alone is what used to come back. Assert the DOM did too — that is
    // the whole failure, and asserting the URL would have passed throughout.
    cy.location('pathname').should('include', 'dashboard_widgets')
    cy.get('[data-widget-key]').should('have.length.greaterThan', 0)
  })

  // The cause, asserted directly. The symptom above is two navigations removed
  // from it, so a future change could reintroduce the orphan entries in a way
  // that spec happens not to catch.
  it('writes history entries Turbo can restore', () => {
    cy.window().then((win) => {
      expect(Boolean(win.history.state?.turbo), 'the page load itself').to.equal(true)
    })

    enter()
    cy.location('search').should('include', 'editing=1')
    cy.window().then((win) => {
      expect(Boolean(win.history.state?.turbo), 'entering edit mode').to.equal(true)
    })

    leave()
    cy.window().then((win) => {
      expect(Boolean(win.history.state?.turbo), 'leaving edit mode').to.equal(true)
    })
  })

  // Back still LEAVES edit mode, which is what the `popstate` listener is for.
  // Routing through Turbo must not cost that.
  it('leaves edit mode when you press back', () => {
    enter()
    cy.get('.editing').should('exist')

    cy.go('back')

    cy.get('.editing').should('not.exist')
    cy.location('search').should('not.include', 'editing=1')
  })
})
