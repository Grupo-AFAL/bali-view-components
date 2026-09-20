// A Turbo morph used to strip the `open` attribute off a panel opened with `showModal()`, and
// from there the page could not be released (#855).
//
// Idiomorph writes every attribute the new node carries and DELETES every one the old node has
// and the new one does not. The markup the server sends for an open panel is a CLOSED panel, so
// the morph takes `open` and the opening class with it. And removing the attribute from a
// `<dialog>` opened with `showModal()` does NOT take it out of the top layer: the document stays
// inert, the UA stops painting the panel, and `close()` returns early —without throwing— on a
// dialog without the attribute. Nothing is left to give the page back.
//
// Measured with `element.matches(':modal')`, which is what actually decides whether the rest of
// the document is inert. Reading classes or the `open` attribute reports a healthy page while it
// is dead.
describe('A morph cannot leave the page inert', () => {
  // The dummy app lives above the preview path `baseUrl` points at; a literal
  // `http://localhost:3001` ignores CYPRESS_BASE_URL and tests another checkout's server.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  const mainDrawer = win => win.document.getElementById('main-drawer')

  const openTheDrawer = () => {
    cy.get('[data-action*="drawer#open"]').first().click()
    cy.get('#main-drawer').should('have.class', 'drawer-open')
    // The content arrives by fetch; the Cancel that closes the panel comes with it.
    cy.get('#main-drawer button[data-action*="drawer#close"]').should('exist')
    cy.window().should(win => {
      expect(mainDrawer(win).matches(':modal'), ':modal on open').to.equal(true)
    })
  }

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}/admin/studios`)
    cy.get('#main-drawer').should('exist')
  })

  it('leaves the panel that is open out of the morph', () => {
    openTheDrawer()

    // Control: an attribute the server markup does not carry. If the morph really ran it takes
    // it away, which is exactly what it was doing to `open`. Without this, a morph that never
    // happened would look the same as one that respected the panel.
    cy.window().then(win => {
      win.document.body.setAttribute('data-morph-probe', '1')
      win.__morphed = false
      win.addEventListener('turbo:morph', () => { win.__morphed = true }, { once: true })
      // The broadest way to get here, and the one that does not depend on the host writing
      // anything unusual: any `turbo_stream.refresh(method: :morph)` that lands with a panel
      // open, including one broadcast over WebSocket from another session.
      win.Turbo.renderStreamMessage('<turbo-stream action="refresh" method="morph"></turbo-stream>')
    })

    cy.window().its('__morphed', { timeout: 15000 }).should('equal', true)
    cy.get('body').should('not.have.attr', 'data-morph-probe')

    cy.window().should(win => {
      const drawer = mainDrawer(win)
      expect(drawer.hasAttribute('open'), 'open attribute').to.equal(true)
      expect(drawer.matches(':modal'), ':modal after the morph').to.equal(true)
    })
    cy.get('#main-drawer').should('have.class', 'drawer-open')

    // And it is still an ordinary panel: closing it gives the page back.
    cy.get('#main-drawer button[data-action*="drawer#close"]').click()
    cy.window().should(win => {
      expect(mainDrawer(win).matches(':modal'), ':modal on close').to.equal(false)
    })
  })

  it('releases the page even when the panel is already stranded in the top layer', () => {
    // The prevention only covers the panels a controller can see at the moment of the morph.
    // This covers the one already broken — by an earlier version, or by any other code that
    // strips the attribute.
    openTheDrawer()

    cy.window().then(win => {
      const drawer = mainDrawer(win)
      const trigger = win.document.querySelector('[data-action*="drawer#open"]')
      const box = trigger.getBoundingClientRect()
      win.__triggerPoint = [box.left + box.width / 2, box.top + box.height / 2]

      // Exactly what the morph does to an attribute the new markup does not carry.
      drawer.removeAttribute('open')

      expect(drawer.open, 'open prop').to.equal(false)
      expect(drawer.matches(':modal'), 'still in the top layer').to.equal(true)

      // The symptom, measured where it shows: the point of the page's trigger does not reach the
      // trigger. Over a bare `<dialog>` `elementFromPoint` returns `HTML` there —the document is
      // inert even for hit-testing—, but Bali's drawer keeps `display: block` when closed (which
      // is what lets it slide out instead of disappearing), so its full-screen `.drawer-overlay`
      // is still the first thing hit. The panel is invisible and keeps the page all the same.
      const hit = win.document.elementFromPoint(...win.__triggerPoint)
      expect(drawer.contains(hit), 'the trigger point is inside the stranded panel').to.equal(true)
    })

    // `{ force: true }`: the UA stopped painting the panel, so its button has no box. That is the
    // state under test, not a shortcut around a wait.
    cy.get('#main-drawer button[data-action*="drawer#close"]').click({ force: true })

    cy.window().should(win => {
      expect(mainDrawer(win).matches(':modal'), ':modal after closing').to.equal(false)
    })

    // The proof that the page came back: a real click on the trigger that was covered, WITHOUT
    // `force`. `cy.click()` fails if anything covers the target, which is exactly the state being
    // left behind. That it also reopens the panel shows the controller is still intact.
    cy.get('[data-action*="drawer#open"]').first().click()
    cy.get('#main-drawer').should('have.class', 'drawer-open')
  })

  it('does not interfere with the morph of a closed panel', () => {
    // The cancellation has to be of the OPEN panel and nothing else: freezing the element and its
    // subtree would always leave the closed panel never updating.
    cy.window().then(win => {
      mainDrawer(win).setAttribute('data-morph-probe', '1')
      win.__morphed = false
      win.addEventListener('turbo:morph', () => { win.__morphed = true }, { once: true })
      win.Turbo.renderStreamMessage('<turbo-stream action="refresh" method="morph"></turbo-stream>')
    })

    cy.window().its('__morphed', { timeout: 15000 }).should('equal', true)
    cy.get('#main-drawer').should('not.have.attr', 'data-morph-probe')
  })
})
