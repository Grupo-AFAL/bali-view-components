// `edit-mode` on its own, with no widget grid around it.
//
// The controller lives in the general controllers directory, so the thing worth
// proving is that it behaves like a general controller: two regions on one page
// are independent, and the query param each remembers itself in is theirs. A
// hardcoded `editing` — which is what shipped first — made that impossible, and
// nothing else in the app puts two on a page, so nothing else would catch it.
const appOrigin = new URL(Cypress.config('baseUrl')).origin

describe('edit-mode', () => {
  const region = (id) => `#region-${id}`
  const enter = (id) => cy.get(`${region(id)} [data-edit-mode-target="enter"] button`).click()
  const leave = (id) => cy.get(`${region(id)} [data-edit-mode-target="leave"] button`).click()

  beforeEach(() => {
    cy.visit(`${appOrigin}/edit_mode_demo`)
  })

  it('enters one region without touching the other', () => {
    enter('alpha')

    cy.get(region('alpha')).should('have.class', 'editing')
    cy.get(region('beta')).should('not.have.class', 'editing')
  })

  // Each region owns its own param. Under a shared `editing` both would read the
  // same flag and enter together.
  it('remembers each region under its own query param', () => {
    enter('alpha')
    cy.location('search').should('contain', 'editing_alpha')
    cy.location('search').should('not.contain', 'editing_beta')

    enter('beta')
    cy.location('search').should('contain', 'editing_alpha')
    cy.location('search').should('contain', 'editing_beta')
  })

  it('leaves one region and leaves the other alone', () => {
    enter('alpha')
    enter('beta')

    leave('alpha')

    cy.get(region('alpha')).should('not.have.class', 'editing')
    cy.get(region('beta')).should('have.class', 'editing')
    cy.location('search').should('not.contain', 'editing_alpha')
    cy.location('search').should('contain', 'editing_beta')
  })

  // The mode is in the URL so Back leaves the mode rather than the page.
  it('restores a region from its param on load', () => {
    cy.visit(`${appOrigin}/edit_mode_demo?editing_beta=1`)

    cy.get(region('beta')).should('have.class', 'editing')
    cy.get(region('alpha')).should('not.have.class', 'editing')
  })

  // `inert`, not `pointer-events-none`: the latter stops the mouse and leaves
  // every link in the tab order.
  it('marks only the edited region inert', () => {
    enter('alpha')

    cy.get(`${region('alpha')} [data-edit-mode-target="inert"]`)
      .should(($el) => expect($el[0].inert).to.equal(true))
    cy.get(`${region('beta')} [data-edit-mode-target="inert"]`)
      .should(($el) => expect($el[0].inert).to.equal(false))
  })

  it('announces the transition for screen readers', () => {
    enter('alpha')

    cy.get(`${region('alpha')} [role="status"]`).should('contain', 'Editing alpha')
  })

  // Escape only acts on a region that is actually in edit mode.
  it('leaves on Escape, and only where the mode is on', () => {
    enter('beta')
    cy.get('body').type('{esc}')

    cy.get(region('beta')).should('not.have.class', 'editing')
    cy.get(region('alpha')).should('not.have.class', 'editing')
  })
})
