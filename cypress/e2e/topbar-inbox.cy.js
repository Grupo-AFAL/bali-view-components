// #1512 — the one topbar icon. Its popover hangs off <body> (tippy), loads the dummy's
// /inbox/popover only when it first opens, and gives the focus back when it closes.
describe('Topbar inbox', () => {
  const trigger = 'a.bali-topbar-inbox-trigger'
  const panel = '#bali-inbox-panel'

  // Through the browser's own keyboard path (CDP), so Escape reaches the document the way a
  // person's key does.
  const sendKey = (key, code, keyCode) => {
    const send = (type) => Cypress.automation('remote:debugger:protocol', {
      command: 'Input.dispatchKeyEvent',
      params: { type, key, code, windowsVirtualKeyCode: keyCode, nativeVirtualKeyCode: keyCode }
    })
    return cy.then(() => send('rawKeyDown').then(() => send('keyUp')))
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
  })

  it('the Avisos tab loads on its first click', () => {
    cy.intercept('GET', '**/inbox/popover?tab=notices*').as('notices')
    cy.get(trigger).click()
    cy.wait('@popover')

    cy.get(`${panel} [role="tab"]`).eq(1).click()

    cy.wait('@notices')
    cy.get('#bali-inbox-popover-notices').should('exist')
  })
})
