// #984 — `submit_group(..., drawer: true)` on a full page: the button's `drawer#submit`
// and the Cancel's `drawer#close` land on the orphan controller AppLayout mounts on
// `<main>` (`data-controller="modal drawer"`, with no targets). The guards hand the events
// back to the browser BEFORE the preventDefault: the submit degrades to the normal form
// submit and the Cancel navigates. Before the guard this was the dead button with an
// endless spinner, the 422 eaten by `_replaceContent` and the Cancel swallowed.
//
// The preview sends by GET to its own URL, so the proof that the submit went out through
// the browser path is the query string — same criterion as simple-filters-auto-submit.
const PREVIEW = '/bali/app_layout/orphan_drawer_form'

describe('drawer: true orphan on a full page (#984)', () => {
  it('the submit degrades to the normal form submit and the button does not go dead', () => {
    cy.visit(PREVIEW)
    cy.get('form button[type="submit"]').click()

    cy.location('search').should('include', 'probe=1')
    cy.get('form button[type="submit"]').should('not.be.disabled')
    cy.get('form button[type="submit"] .loading-spinner').should('not.exist')
  })

  it('the Cancel navigates instead of swallowing the click', () => {
    cy.visit(PREVIEW)
    cy.contains('a', /cancel/i).click()

    cy.location('search').should('include', 'cancelled=1')
  })
})
