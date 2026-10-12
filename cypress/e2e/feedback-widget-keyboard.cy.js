// The panel is a Drawer whose only content is Opina's frame, and the Drawer's Tab trap left the
// frame out of what Tab can land on: with the ✕ as both ends of the trap, Tab and Shift+Tab
// from it came back to it, and Opina's form could not be reached from the keyboard.
describe('FeedbackWidget panel from the keyboard', () => {
  // The dummy app lives above the Lookbook preview path `baseUrl` points at.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const close = '#feedback-widget .drawer-header button'
  const expectFocusOnFrame = label => cy.document().should((doc) => {
    expect(doc.activeElement, label).to.equal(doc.querySelector('#feedback-widget iframe'))
  })

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}/feedback-widget-demo`)
    cy.get('[data-action="feedback-widget#open"]').click()
    cy.get('#feedback-widget').should('have.class', 'drawer-open')
    cy.get('#feedback-widget iframe').its('0.contentDocument.body').find('#go-deeper').should('exist')
  })

  it('reaches the frame with Tab from the ✕', () => {
    cy.get(close).focus()
    cy.press(Cypress.Keyboard.Keys.TAB)
    expectFocusOnFrame('Tab from the ✕')
  })

  // #1386 — the frame's last control is the trap's edge, and neither wrap may stop on a focus
  // nobody can see: forward on `<body>`, outside the dialog; backward on the frame itself, with
  // nothing focused inside it. The step into the frame is the browser's own, so a synthetic
  // keydown cannot take it: these go through its keyboard path (CDP). `cy.press` takes no
  // modifiers.
  const lastControl = 'request-capture'
  const shiftTab = () => {
    const key = { key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9, nativeVirtualKeyCode: 9, modifiers: 8 }
    const send = (type) => Cypress.automation('remote:debugger:protocol', {
      command: 'Input.dispatchKeyEvent',
      params: { type, ...key }
    })

    return cy.then(() => send('rawKeyDown').then(() => send('keyUp')))
  }

  it('goes from the ✕ with Shift+Tab straight to the last control in the frame', () => {
    cy.get(close).focus()
    shiftTab()

    cy.get('#feedback-widget iframe').should(($frame) => {
      expect($frame[0].ownerDocument.activeElement, 'the page').to.equal($frame[0])
      expect($frame[0].contentDocument.activeElement.id, 'inside the frame').to.equal(lastControl)
    })
  })

  it('goes from the last control in the frame with Tab straight to the ✕', () => {
    cy.get('#feedback-widget iframe').its('0.contentDocument').then((doc) => {
      doc.getElementById(lastControl).focus()
    })
    cy.press(Cypress.Keyboard.Keys.TAB)

    cy.document().should((doc) => {
      expect(doc.activeElement, 'Tab from the last control in the frame').to.equal(doc.querySelector(close))
    })
  })

  // Escape pressed inside the frame stays in the frame's document: the page sees neither the
  // key nor the `<dialog>`'s `cancel`. The embed asks for the close by message, as the
  // stand-in does; the count proves the request was sent, so a panel left open is the widget's.
  context('closing from inside the frame', () => {
    const closeRequest = 'bali:feedback:close-request'
    const countCloseRequests = () => cy.window().then((win) => {
      win.__closeRequests = 0
      win.addEventListener('message', (event) => {
        if (event.data?.type === closeRequest) win.__closeRequests += 1
      })
    })
    const expectPanel = (open) => cy.get('#feedback-widget').should(($dialog) => {
      expect($dialog[0].matches(':modal'), ':modal').to.equal(open)
      expect($dialog.hasClass('drawer-open'), 'drawer-open').to.equal(open)
    })

    it('closes the panel on Escape pressed in the embed', () => {
      countCloseRequests()
      cy.get('#feedback-widget iframe').its('0.contentDocument').then((doc) => {
        doc.getElementById(lastControl).focus()
      })
      cy.press(Cypress.Keyboard.Keys.ESC)

      cy.window().its('__closeRequests').should('equal', 1)
      expectPanel(false)
    })

    it('ignores a close request that did not come from its own frame', () => {
      countCloseRequests()
      cy.window().then((win) => win.postMessage({ type: closeRequest }, appOrigin))

      cy.window().its('__closeRequests').should('equal', 1)
      // Nothing to wait for on success: a whole turn of the event loop for it to be acted on.
      cy.wait(250)
      expectPanel(true)
    })
  })
})
