// What the Back button does after `ModalController#_replaceBodyAndURL` swaps the
// document.
//
// `EditModeController` (widget grid) has a measured, documented cost on its own
// history push: Turbo issues a restoration visit — one wasted GET of a page that
// never changed — because Turbo's snapshot cache is keyed by URL and populated
// only by `view.cacheSnapshot()` during a real visit AWAY from a page. Its spec
// noted that `modal/index.js` uses the same push-then-swap-body pattern, that
// nothing in `cypress/e2e/` exercised its Back path, and that it was therefore
// worth checking separately. This is that check.
//
// The measured answer: the same benign cost, and nothing worse. Back works, the
// JS realm survives it, and it spends exactly one restoration GET.
//
// The path runs only when a modal trigger's fetch is REDIRECTED — the modal
// stops being a panel and becomes a navigation. `/modal_redirect` in the dummy
// app exists to produce exactly that; nothing else in the app reaches this
// branch, which is why it went unverified.

// `baseUrl` points at the Lookbook preview mount; these are real app pages.
const appOrigin = new URL(Cypress.config('baseUrl')).origin

describe('modal history', () => {
  beforeEach(() => {
    cy.visit(`${appOrigin}/modal_redirect`)
  })

  it('replaces the document and the URL when the trigger redirects', () => {
    cy.get('#modal-redirect-origin').should('exist')
    cy.get('#redirecting-trigger').click()

    cy.location('pathname').should('eq', '/modal_redirect/landing')
    cy.get('#modal-redirect-landing').should('exist')
    cy.get('#modal-redirect-origin').should('not.exist')
  })

  // The swap is `document.body.innerHTML = …` plus a history push, so the realm
  // is never torn down — which is the whole reason the pushed entry has no
  // snapshot behind it.
  it('swaps the body without reloading the page', () => {
    cy.window().then((win) => { win.__cySurvivesSwap = true })
    cy.get('#redirecting-trigger').click()
    cy.get('#modal-redirect-landing').should('exist')

    cy.window().should('have.prop', '__cySurvivesSwap', true)
  })

  it('returns to the origin page on Back', () => {
    cy.get('#redirecting-trigger').click()
    cy.get('#modal-redirect-landing').should('exist')

    cy.go('back')

    cy.location('pathname').should('eq', '/modal_redirect')
    cy.get('#modal-redirect-origin').should('exist')
  })

  // The signal a hard reload cannot fake: the realm standing after Back is the
  // one that was standing before it. So Back is a Turbo restoration visit that
  // re-renders into the live page, not a browser-level reload.
  it('leaves the page via history, not a full reload', () => {
    cy.get('#redirecting-trigger').click()
    cy.get('#modal-redirect-landing').should('exist')
    cy.window().then((win) => { win.__cySurvivesBack = true })

    cy.go('back')
    cy.get('#modal-redirect-origin').should('exist')

    cy.window().should('have.prop', '__cySurvivesBack', true)
  })

  // The cost, asserted rather than asserted away — the same one the widget grid
  // accepts and for the same architectural reason. `_replaceBodyAndURL` pushes
  // the destination's URL, but Turbo never visited the origin page away, so no
  // snapshot was ever cached for it and `action: "restore"` falls back to the
  // network. One GET of a page that has not changed.
  //
  // Closing it would mean calling `Turbo.session.view.cacheSnapshot()` — private
  // API, not exposed on `window.Turbo` — from a shared library controller. This
  // asserts the count so that a future change which makes it WORSE (two GETs, or
  // a hard reload) fails here rather than going unnoticed.
  it('costs exactly one restoration GET on Back', () => {
    cy.intercept('GET', `${appOrigin}/modal_redirect`).as('originGet')

    cy.get('#redirecting-trigger').click()
    cy.get('#modal-redirect-landing').should('exist')

    cy.go('back')
    cy.get('#modal-redirect-origin').should('exist')

    cy.get('@originGet.all').should('have.length', 1)
  })
})
