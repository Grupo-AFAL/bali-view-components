// The embed is cross-origin to the page it is collecting a bug report about, so there are
// two things it cannot get for itself: the address of that page (`document.referrer` gives
// it the origin and stops there) and a picture of it. Both are the host's to hand over, and
// the picture has the extra problem that the panel is sitting on top of the very thing being
// photographed.
//
// The screen-capture picker is browser chrome and no test can click it, so `getDisplayMedia`
// is stubbed here. What is NOT stubbed is everything the controller does with the stream —
// hiding the panel, waiting for a frame composited after it went away, drawing it, sending
// it — which is the part that can be wrong.
describe('FeedbackWidget screen capture', () => {
  // The dummy app lives above the Lookbook preview path `baseUrl` points at, so the origin
  // is derived from it rather than written out. A literal `http://localhost:3001` ignores
  // CYPRESS_BASE_URL and quietly tests another checkout's server from a git worktree.
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const demoPath = '/feedback-widget-demo'

  // Stands in for the picker's output: a canvas repainted every frame, GREEN while the
  // widget has hidden its panel and RED while the panel is on screen. Whatever colour comes
  // back in the finished picture is a direct answer to the only question the timing code
  // exists to settle — was the frame composited after the panel went away, or before.
  const stubbedPicker = win => {
    const canvas = win.document.createElement('canvas')
    canvas.width = 32
    canvas.height = 32
    const context = canvas.getContext('2d')

    const paint = () => {
      const hidden = !!win.document.querySelector('.feedback-widget[data-capturing]')
      context.fillStyle = hidden ? 'rgb(0, 255, 0)' : 'rgb(255, 0, 0)'
      context.fillRect(0, 0, canvas.width, canvas.height)
      win.requestAnimationFrame(paint)
    }
    win.requestAnimationFrame(paint)

    return () => Promise.resolve(canvas.captureStream(30))
  }

  // `getDisplayMedia` lives on MediaDevices.prototype and the navigator's `mediaDevices` is
  // read-only, so it is defined over rather than assigned.
  const install = (win, getDisplayMedia) => {
    if (!win.navigator.mediaDevices) {
      Object.defineProperty(win.navigator, 'mediaDevices', { configurable: true, value: {} })
    }

    Object.defineProperty(win.navigator.mediaDevices, 'getDisplayMedia', {
      configurable: true,
      value: getDisplayMedia
    })
  }

  // `picker` is a factory: it is handed the window under test and returns the
  // `getDisplayMedia` to install in it.
  const visitDemo = (picker = stubbedPicker) => {
    cy.viewport(1280, 900)
    cy.visit(`${appOrigin}${demoPath}`, {
      onBeforeLoad (win) {
        install(win, picker(win))
      }
    })
    cy.get('#feedback-widget').should('exist')
  }

  const openWidget = () => {
    cy.get('[data-action="feedback-widget#open"]').click()
    cy.get('#feedback-widget').should('have.class', 'drawer-open')
  }

  // The stand-in embed is served by the dummy itself, so it is same-origin and its document
  // is reachable. In production it is Opina and it is not — which is what the whole message
  // protocol under test is for.
  //
  // The Cypress subject stays the `<iframe>` element, which never moves, and everything
  // inside is read from within the retrying callback. Wrapping an element out of the frame's
  // document does not survive this suite: the embed navigates inside the frame, and the
  // subject Cypress is holding detaches mid-chain.
  const expectInEmbed = (selector, assert) =>
    cy.get('#feedback-widget iframe').should(($frame) => {
      const element = $frame[0].contentDocument.querySelector(selector)
      expect(element, selector).to.not.equal(null)
      assert(element.textContent)
    })

  const expectText = (selector, expected) =>
    expectInEmbed(selector, (text) => expect(text, selector).to.equal(expected))

  // A native click, for the same reason: there is no Cypress subject to lose. The wait and
  // the click are separate commands on purpose — `should` retries its callback, and a click
  // is not something to do twice.
  const clickInEmbed = (selector) => {
    expectInEmbed(selector, () => {})

    return cy.get('#feedback-widget iframe').then(($frame) => {
      $frame[0].contentDocument.querySelector(selector).click()
    })
  }

  it('hands the embed the address and title of the page being reported on', () => {
    visitDemo()
    openWidget()

    expectText('#host-url', `${appOrigin}${demoPath}`)
    expectInEmbed('#host-title', (text) => expect(text).to.not.equal('(none)'))
    expectText('#capture-supported', 'true')
    // The HOST's viewport. The frame's own would be the width of the panel, which says
    // nothing about the page the report is about.
    expectInEmbed('#host-viewport', (text) => expect(text).to.match(/^\d{3,}x\d{3,}$/))
  })

  // The embed navigates inside the frame — a list, a report, the form — and the form is
  // the only page that ever wants a screenshot. Sent once on the first load, the context
  // reached the page nobody needed it on: by the time someone was writing the report, the
  // document that knew where it was had been replaced, and the button never appeared.
  it('tells the embed where it is again after it navigates inside the frame', () => {
    visitDemo()
    openWidget()

    expectText('#capture-supported', 'true')
    clickInEmbed('#go-deeper')

    // The new document starts out knowing nothing, and is told.
    expectText('#query-string', 'paso=2')
    expectText('#host-url', `${appOrigin}${demoPath}`)
    expectText('#capture-supported', 'true')
  })

  it('still answers a capture request after that navigation', () => {
    visitDemo()
    openWidget()

    clickInEmbed('#go-deeper')
    expectText('#query-string', 'paso=2')

    clickInEmbed('#request-capture')
    expectText('#capture-pixel', '0,255,0')
  })

  it('takes the picture with the panel out of the way', () => {
    visitDemo()
    openWidget()

    clickInEmbed('#request-capture')

    expectInEmbed('#capture-status', (text) => expect(text).to.contain('received'))
    // Green: every frame that still had the panel in it was let go by.
    expectText('#capture-pixel', '0,255,0')
  })

  it('puts the panel back once the picture is taken', () => {
    visitDemo()
    openWidget()

    clickInEmbed('#request-capture')
    expectInEmbed('#capture-status', (text) => expect(text).to.contain('received'))

    cy.get('.feedback-widget').should('not.have.attr', 'data-capturing')
    cy.get('#feedback-widget').should('have.class', 'drawer-open')
    cy.get('#feedback-widget').should('have.css', 'opacity', '1')
  })

  it('tells the embed the difference between a refusal and a browser that cannot', () => {
    visitDemo(() => () => Promise.reject(
      Object.assign(new Error('Permission denied'), { name: 'NotAllowedError' })
    ))
    openWidget()

    clickInEmbed('#request-capture')
    expectText('#capture-status', 'error: denied')
  })

  // The host is being asked to put a screen-share prompt in front of the user. Only the
  // frame it loaded itself gets to ask; a message from anywhere else on the page — same
  // origin or not — is not a request.
  it('ignores a capture request that did not come from its own frame', () => {
    visitDemo()
    openWidget()

    cy.window().then(win => {
      cy.spy(win.navigator.mediaDevices, 'getDisplayMedia').as('picker')
      win.postMessage({ type: 'bali:feedback:capture-request' }, appOrigin)
    })

    // Nothing to wait for on success, so the assertion is made after the message has had a
    // whole turn of the event loop to be acted on.
    cy.wait(250)
    cy.get('@picker').should('not.have.been.called')
    cy.get('.feedback-widget').should('not.have.attr', 'data-capturing')
  })
})
