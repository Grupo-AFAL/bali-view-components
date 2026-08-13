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
  const embed = () =>
    cy.get('#feedback-widget iframe')
      .its('0.contentDocument.body')
      .should('not.be.empty')
      .then(cy.wrap)

  it('hands the embed the address and title of the page being reported on', () => {
    visitDemo()
    openWidget()

    embed().find('#host-url').should('have.text', `${appOrigin}${demoPath}`)
    embed().find('#host-title').should('not.have.text', '(none)')
    embed().find('#capture-supported').should('have.text', 'true')
    // The HOST's viewport. The frame's own would be the width of the panel, which says
    // nothing about the page the report is about.
    embed().find('#host-viewport').invoke('text').should('match', /^\d{3,}x\d{3,}$/)
  })

  it('takes the picture with the panel out of the way', () => {
    visitDemo()
    openWidget()

    embed().find('#request-capture').click()

    embed().find('#capture-status').should('contain', 'received')
    // Green: every frame that still had the panel in it was let go by.
    embed().find('#capture-pixel').should('have.text', '0,255,0')
  })

  it('puts the panel back once the picture is taken', () => {
    visitDemo()
    openWidget()

    embed().find('#request-capture').click()
    embed().find('#capture-status').should('contain', 'received')

    cy.get('.feedback-widget').should('not.have.attr', 'data-capturing')
    cy.get('#feedback-widget').should('have.class', 'drawer-open')
    cy.get('#feedback-widget').should('have.css', 'opacity', '1')
  })

  it('tells the embed the difference between a refusal and a browser that cannot', () => {
    visitDemo(() => () => Promise.reject(
      Object.assign(new Error('Permission denied'), { name: 'NotAllowedError' })
    ))
    openWidget()

    embed().find('#request-capture').click()
    embed().find('#capture-status').should('have.text', 'error: denied')
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
