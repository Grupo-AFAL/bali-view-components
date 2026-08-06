// The camera is the one thing a headless browser cannot hand us, so every spec
// here replaces `navigator.mediaDevices.getUserMedia` before the page loads.
//
// Two of them reject, which is the whole point: qr-scanner swallows every
// getUserMedia rejection and rethrows one string, so the controller asks the
// browser a second time to learn *why* it failed. These specs are what keeps
// "blocked" and "no camera" from collapsing back into one message.
//
// The third returns a real MediaStream — a canvas with a QR code painted on it,
// captured — so the decode, the event and its payload are exercised for real.
//
// Visibility, never text: every panel is in the document from the first render,
// so `contains(...)` would pass on all five at once.
describe('Bali::QrScanner', () => {
  // The preview opens with autostart off, so nothing touches the camera until
  // the spec presses the button.
  const PREVIEW = '/bali/qr_scanner/default'

  // Replaces the getter on the Navigator instance. `mediaDevices` is read-only
  // on the prototype, so assignment silently does nothing and the spec would
  // measure the real (absent) camera instead of the stub.
  const stubMediaDevices = (win, value) => {
    Object.defineProperty(win.navigator, 'mediaDevices', { value, configurable: true })
  }

  const rejectWith = (win, name) => stubMediaDevices(win, {
    getUserMedia: () => Promise.reject(new win.DOMException(`stubbed ${name}`, name))
  })

  const visitWith = (onBeforeLoad) => cy.visit(PREVIEW, { onBeforeLoad })

  const startCamera = () => cy.get('[data-qr-scanner-panel="idle"] button').click()

  const panel = state => cy.get(`[data-qr-scanner-panel="${state}"]`)

  context('permission states', () => {
    it('renders the idle panel and nothing else before the camera is asked for', () => {
      visitWith(win => rejectWith(win, 'NotAllowedError'))

      panel('idle').should('be.visible')
      panel('requesting').should('not.be.visible')
      panel('denied').should('not.be.visible')
      panel('unavailable').should('not.be.visible')
      panel('scanned').should('not.be.visible')
      cy.get('.qr-scanner-component').should('have.attr', 'data-qr-scanner-state', 'idle')
    })

    it('shows the denied panel when the visitor blocks the camera', () => {
      visitWith(win => rejectWith(win, 'NotAllowedError'))
      startCamera()

      panel('denied').should('be.visible')
      panel('unavailable').should('not.be.visible')
      panel('idle').should('not.be.visible')
      cy.get('.qr-scanner-component').should('have.attr', 'data-qr-scanner-state', 'denied')
    })

    // The distinction the library cannot make on its own: same thrown string,
    // different cause, different thing to tell the visitor.
    it('shows the unavailable panel when the device has no camera', () => {
      visitWith(win => rejectWith(win, 'NotFoundError'))
      startCamera()

      panel('unavailable').should('be.visible')
      panel('denied').should('not.be.visible')
      cy.get('.qr-scanner-component').should('have.attr', 'data-qr-scanner-state', 'unavailable')
    })

    // What an app served over plain http on a real host looks like: no
    // mediaDevices at all, so there is nothing to reject.
    it('shows the unavailable panel outside a secure context', () => {
      visitWith(win => stubMediaDevices(win, undefined))
      startCamera()

      panel('unavailable').should('be.visible')
      cy.get('.qr-scanner-component').should('have.attr', 'data-qr-scanner-state', 'unavailable')
    })

    it('announces the failure on bali:qr-scanner:error', () => {
      visitWith(win => {
        rejectWith(win, 'NotAllowedError')
        win.__errors = []
        win.addEventListener('bali:qr-scanner:error', e => win.__errors.push(e.detail))
      })
      startCamera()

      panel('denied').should('be.visible')
      cy.window().its('__errors').should('have.length', 1)
      cy.window().its('__errors.0.state').should('equal', 'denied')
    })

    // The retry button is the same action as "start" — after a denial the
    // visitor grants permission in the browser chrome and presses it again.
    it('retries from the denied panel', () => {
      visitWith(win => {
        win.__calls = 0
        stubMediaDevices(win, {
          getUserMedia: () => {
            win.__calls += 1
            return Promise.reject(new win.DOMException('nope', 'NotAllowedError'))
          }
        })
      })
      startCamera()
      panel('denied').should('be.visible')

      cy.window().then(win => { win.__callsAfterFirst = win.__calls })
      cy.get('[data-qr-scanner-panel="denied"] button').click()

      cy.window().should(win => {
        expect(win.__calls).to.be.greaterThan(win.__callsAfterFirst)
      })
    })
  })

  context('a stream that carries a code', () => {
    // A canvas with the QR painted on it, captured as a MediaStream. The module
    // matrix comes from the same rqrcode gem Bali::QrCode encodes with, so the
    // fixture and the component under test cannot drift apart by construction —
    // regenerate it with the snippet in the fixture's own README entry.
    const paintingStream = (win, modules) => {
      const SIZE = 480
      const SCALE = 12
      const canvas = win.document.createElement('canvas')
      canvas.width = SIZE
      canvas.height = SIZE
      const ctx = canvas.getContext('2d')

      const draw = () => {
        ctx.fillStyle = '#fff'
        ctx.fillRect(0, 0, SIZE, SIZE)
        ctx.fillStyle = '#000'
        const offset = Math.round((SIZE - modules.length * SCALE) / 2)
        modules.forEach((row, y) => {
          for (let x = 0; x < row.length; x++) {
            if (row[x] === '1') {
              ctx.fillRect(offset + x * SCALE, offset + y * SCALE, SCALE, SCALE)
            }
          }
        })
      }

      draw()
      // A canvas that never changes emits one frame and stops. qr-scanner reads
      // whatever frame is current when it looks, so keep painting.
      win.setInterval(draw, 100)

      return canvas.captureStream(15)
    }

    beforeEach(function () {
      cy.fixture('qr-modules.json').as('qr')
    })

    it('reaches the scanning state and shows no panel', function () {
      const modules = this.qr.modules
      visitWith(win => {
        stubMediaDevices(win, {
          getUserMedia: () => Promise.resolve(paintingStream(win, modules))
        })
      })
      startCamera()

      cy.get('.qr-scanner-component', { timeout: 15000 })
        .should('have.attr', 'data-qr-scanner-state')
        .and('match', /scanning|scanned/)
    })

    it('emits bali:qr-scanner:scan with the decoded value, then releases the camera', function () {
      const modules = this.qr.modules
      visitWith(win => {
        stubMediaDevices(win, {
          getUserMedia: () => Promise.resolve(paintingStream(win, modules))
        })
        win.__scans = []
        win.addEventListener('bali:qr-scanner:scan', e => win.__scans.push(e.detail))
      })
      startCamera()

      cy.window({ timeout: 20000 }).its('__scans.0.value').should('equal', this.qr.payload)

      // stop_on_scan is on by default: the camera is released and the panel
      // offers another go.
      panel('scanned').should('be.visible')
    })
  })
})
