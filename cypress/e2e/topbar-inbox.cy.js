// #1512 — the one topbar icon. Its popover hangs off <body> (tippy), loads the dummy's
// /inbox/popover only when it first opens, and gives the focus back when it closes.
describe('Topbar inbox', () => {
  const trigger = 'a.bali-topbar-inbox-trigger'
  const panel = '#bali-inbox-panel'

  // Through the browser's own keyboard path (CDP), so Escape reaches the document the way a
  // person's key does.
  // `text` is what makes a key activate something: an Enter without it never submits a form.
  const sendKey = (key, code, keyCode, text) => {
    const send = (type) => Cypress.automation('remote:debugger:protocol', {
      command: 'Input.dispatchKeyEvent',
      params: { type, key, code, text, windowsVirtualKeyCode: keyCode, nativeVirtualKeyCode: keyCode }
    })
    return cy.then(() => send(text ? 'keyDown' : 'rawKeyDown').then(() => send('keyUp')))
  }

  beforeEach(() => {
    cy.intercept('GET', '**/inbox/popover*').as('popover')
    cy.visit('/bali/topbar/inbox/default')
  })

  it('sends no popover request before the first click', () => {
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get('[data-controller="topbar-inbox"]').should('exist')
    // Long enough for a lazy frame scrolled into view to have fired.
    cy.wait(500)
    cy.get('@popover.all').should('have.length', 0)
  })

  it('opens on click, loads the frame and moves the focus inside', () => {
    cy.get(trigger).click()

    cy.wait('@popover')
    cy.get(trigger).should('have.attr', 'aria-expanded', 'true')
    cy.get(panel).should('be.visible').and('have.attr', 'role', 'dialog')
    cy.get(`${panel} .bali-inbox-popover-row`).should('have.length.at.least', 1)
    cy.focused().should('have.attr', 'id', 'bali-inbox-panel')
  })

  it('Escape closes it and returns the focus to the icon', () => {
    cy.get(trigger).click()
    cy.wait('@popover')
    cy.get(panel).should('be.visible')

    sendKey('Escape', 'Escape', 27)

    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.focused().should('match', trigger)
  })

  it('a click outside closes it', () => {
    cy.get(trigger).click()
    cy.wait('@popover')
    cy.get(panel).should('be.visible')

    cy.get('body').click(10, 400)

    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
  })

  it('a second open reloads the frame', () => {
    cy.get(trigger).click()
    cy.wait('@popover')
    sendKey('Escape', 'Escape', 27)
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')

    cy.get(trigger).click()

    cy.wait('@popover')
    cy.get('@popover.all').should('have.length', 2)
  })

  it('a modified click is the link, and opens no popover', () => {
    cy.get(trigger).should('have.attr', 'href', '/inbox')
    cy.get(trigger).then(($link) => {
      const doc = $link[0].ownerDocument
      let preventedByController = null
      // On the document, so it runs after the controller's own listener on the link. It records
      // what the controller did and then stops the navigation a real cmd-click would start.
      const record = (event) => {
        preventedByController = event.defaultPrevented
        event.preventDefault()
      }
      doc.addEventListener('click', record, { once: true })
      $link[0].dispatchEvent(new doc.defaultView.MouseEvent('click', { bubbles: true, cancelable: true, metaKey: true }))
      expect(preventedByController, 'the controller left the click alone').to.equal(false)
    })
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get('[data-tippy-root]').should('not.exist')

    // The same link, clicked plainly, does open it: the controller was there all along.
    cy.get(trigger).click()
    cy.wait('@popover')
    cy.get(trigger).should('have.attr', 'aria-expanded', 'true')
  })

  // The panel hangs off <body> while open and the row's link leaves the page from inside it.
  it('Back after following a row leaves a closed popover and a working icon', () => {
    cy.get(trigger).click()
    cy.wait('@popover')
    cy.get(`${panel} .bali-inbox-popover-row`).first().click()
    cy.location('pathname').should('not.include', '/lookbook')

    cy.go('back')

    cy.location('pathname').should('include', '/bali/topbar/inbox/default')
    cy.get('[data-tippy-root]').should('not.exist')
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get(trigger).click()
    cy.get(panel).should('be.visible')
  })

  // What Bali::Inbox::Badge.refresh broadcasts: a fresh Bali::Topbar::Inbox::Component::SIGNAL_ID
  // element and no count. Its arrival is what makes the icon fetch its own badge.
  it('a new notice on the stream makes the icon fetch its badge', () => {
    cy.intercept('GET', '**/inbox/badge').as('badge')
    cy.get('#bali-inbox-signal').should('exist')

    cy.window().then((win) => win.Turbo.renderStreamMessage(
      '<turbo-stream action="replace" target="bali-inbox-signal"><template>' +
      '<span id="bali-inbox-signal" hidden data-topbar-inbox-target="signal"></span></template></turbo-stream>'
    ))

    cy.wait('@badge')
    cy.get('#bali-inbox-badge .sr-only').should('exist')
  })

  it('marking every notice read from the popover clears the icon\'s dot', () => {
    cy.task('railsRunner', 'Movie.order(:id).first.notify(recipient: User.demo, kind: :movie_released, ' +
            'message: "A notice for Cypress")')
    cy.get(trigger).click()
    cy.wait('@popover')
    cy.get(`${panel} .bali-inbox-popover-row`).should('exist')
    cy.get('.bali-topbar-inbox-dot').should('exist')

    cy.get(`${panel} [role="tab"]`).eq(1).click()
    // By keyboard, as a person reaching it with Tab would: that is what leaves the focus on it.
    cy.get('#bali-inbox-popover-notices button[type="submit"]').focus()
    sendKey('Enter', 'Enter', 13, '\r')

    cy.get('.bali-topbar-inbox-dot').should('not.exist')
    cy.get(`${trigger} .sr-only`).should('not.contain', 'unread')
    // The button that had the focus was redrawn; the focus stays in the dialog.
    cy.focused().should('have.attr', 'id', 'bali-inbox-panel')
  })

  it('the Avisos tab loads on its first click', () => {
    cy.intercept('GET', '**/inbox/popover?tab=notices*').as('notices')
    cy.get(trigger).click()
    cy.wait('@popover')
    // The skeleton's tabs are inert; these are the loaded ones.
    cy.get(`${panel} .bali-inbox-popover-row`).should('exist')

    cy.get(`${panel} [role="tab"]`).eq(1).click()

    cy.wait('@notices')
    cy.get('#bali-inbox-popover-notices').should('exist')
  })
})
