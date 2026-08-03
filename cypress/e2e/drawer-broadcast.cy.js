// A `drawer#open` trigger usually names no drawer — the common page has one shared overlay,
// so `ModalController#open` dispatches `bali:drawer:open` as a broadcast. Every drawer with
// the three targets used to answer it, on the assumption that a page carries one. The
// package breaks that assumption itself: `Bali::FeedbackWidget` ships its own drawer, so on
// any page with the widget an ordinary "New…" trigger opened TWO drawers. Only the one
// holding the submitted form is closed afterwards, and the other stayed `showModal()`-ed —
// a `<dialog>` in the top layer makes the whole document outside it inert, so the page went
// on looking normal and stopped answering the mouse (#854).
//
// This lives against the dummy's `/admin/studios`, not a Lookbook preview, because the
// defect needs the composition a host actually ships: AppLayout's shared drawer AND the
// feedback widget on one page, with a real form submit in between.
describe('Drawer broadcast addressing', () => {
  // The dummy app lives above the Lookbook preview path `baseUrl` points at, so the origin
  // is derived from it rather than written out. A literal `http://localhost:3001` ignores
  // CYPRESS_BASE_URL and quietly tests another checkout's server from a git worktree.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  const inTopLayer = win =>
    Array.from(win.document.querySelectorAll('dialog'))
      .filter(d => d.matches(':modal'))
      .map(d => d.id || '(anon)')

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}/admin/studios`)
    cy.get('#feedback-widget').should('exist')
  })

  it('opens only the shared drawer, leaving the feedback widget alone', () => {
    cy.get('[data-action*="drawer#open"]').first().click()

    cy.get('#main-drawer').should('have.class', 'drawer-open')
    cy.get('#feedback-widget').should('not.have.class', 'drawer-open')
    cy.window().then(win => {
      expect(inTopLayer(win)).to.deep.equal(['main-drawer'])
    })
  })

  it('leaves nothing in the top layer after the form is submitted', () => {
    cy.get('[data-action*="drawer#open"]').first().click()
    cy.get('#main-drawer').should('have.class', 'drawer-open')
    cy.wait(800) // the panel slides in; typing into it before that retargets the click

    cy.get('#main-drawer input[name*="[name]"]').type('Broadcast Studio', { force: true })
    cy.get('#main-drawer [data-action*="drawer#submit"]').click({ force: true })

    cy.get('#main-drawer', { timeout: 10000 }).should('not.have.class', 'drawer-open')
    cy.window().should(win => {
      // The measurement that matters: `:modal` is what makes the rest of the page inert.
      // Reading class names or the `open` attribute would have passed while the page was dead.
      expect(inTopLayer(win)).to.deep.equal([])
    })
  })

  it('still opens the feedback widget from its own trigger, and only that one', () => {
    cy.get('[data-action*="feedback-widget#open"]').click()

    cy.get('#feedback-widget').should('have.class', 'drawer-open')
    cy.get('#main-drawer').should('not.have.class', 'drawer-open')
    cy.window().then(win => {
      expect(inTopLayer(win)).to.deep.equal(['feedback-widget'])
    })
  })
})
