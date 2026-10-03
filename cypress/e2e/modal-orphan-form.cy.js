// #984 — `submit_group(..., drawer: true)` on a full page: the button's `drawer#submit`
// and the Cancel's `drawer#close` land on the orphan `drawer` controller AppLayout mounts on
// `<body>` (it has no targets). The guards hand the events back to the browser BEFORE the
// preventDefault: the submit degrades to the normal form submit and the Cancel navigates.
// Before the guard this was the dead button with an endless spinner, the 422 eaten by
// `_replaceContent` and the Cancel swallowed.
//
// The preview sends by GET to its own URL, so the proof that the submit went out through
// the browser path is the query string — same criterion as simple-filters-auto-submit.
const PREVIEW = '/bali/app_layout/orphan_drawer_form'

// With no drawer controller above the form, Stimulus binds neither action and the browser
// submits and navigates on its own: both tests would pass with nothing to guard.
const expectOrphanDrawerAboveTheForm = () => {
  cy.get('form').should(($form) => {
    const host = $form[0].closest('[data-controller~="drawer"]')
    expect(host, 'a drawer controller above the form').to.not.equal(null)
    const drawer = $form[0].ownerDocument.defaultView.Stimulus
      .getControllerForElementAndIdentifier(host, 'drawer')
    expect(drawer, 'connected').to.not.equal(null)
    expect(drawer.hasTemplateTarget, 'with no panel of its own').to.equal(false)
  })
}

describe('drawer: true orphan on a full page (#984)', () => {
  beforeEach(() => {
    cy.visit(PREVIEW)
    expectOrphanDrawerAboveTheForm()
  })

  it('the submit degrades to the normal form submit and the button does not go dead', () => {
    cy.get('form button[type="submit"]').click()

    cy.location('search').should('include', 'probe=1')
    cy.get('form button[type="submit"]').should('not.be.disabled')
    cy.get('form button[type="submit"] .loading-spinner').should('not.exist')
  })

  it('the Cancel navigates instead of swallowing the click', () => {
    cy.contains('a', /cancel/i).click()

    cy.location('search').should('include', 'cancelled=1')
  })
})
