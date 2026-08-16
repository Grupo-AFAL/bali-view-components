// The widget's panel holds two things: the drawer header and the frame. The drawer template
// writes `p-6` on `.drawer-inner` as a Tailwind utility, and the widget's own sheet said
// `padding: 0` from @layer components — where it lost, silently, because utilities are the
// last layer. So the panel had been showing 24px against the header's 16px ever since the
// widget was composed out of Bali::Drawer, and nobody could see it in the CSS.
describe('FeedbackWidget panel alignment', () => {
  // The dummy app lives above the Lookbook preview path `baseUrl` points at, so the origin
  // is derived from it rather than written out. A literal `http://localhost:3001` ignores
  // CYPRESS_BASE_URL and quietly tests another checkout's server from a git worktree.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}/feedback-widget-demo`)
    cy.get('[data-action="feedback-widget#open"]').click()
    cy.get('#feedback-widget').should('have.class', 'drawer-open')
  })

  it('gives the frame the same padding as the header above it', () => {
    cy.get('#feedback-widget .drawer-header').should('have.css', 'padding', '16px')
    cy.get('#feedback-widget .drawer-inner').should('have.css', 'padding', '16px')
  })

  // Scoped to this widget: every other drawer on the page keeps the `p-6` it always had.
  it('leaves other drawers on their own padding', () => {
    cy.visit(`${appOrigin}/admin/studios`)
    cy.get('[data-action*="drawer#open"]').first().click()
    cy.get('#main-drawer').should('have.class', 'drawer-open')

    cy.get('#main-drawer .drawer-inner').should('have.css', 'padding', '24px')
  })
})
