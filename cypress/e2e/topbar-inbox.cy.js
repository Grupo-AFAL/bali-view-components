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

  // A document's file name has no spaces to break at. It wraps inside the panel instead of
  // scrolling it sideways, at the panel's 560px and at a phone's width (16px gutter each side).
  it('a title with no spaces wraps instead of scrolling the panel sideways', () => {
    const title = 'CAP-FOR-97_Solicitud_para_Capacitacion_Tecnica_o_Especializada_del_Personal'
    const clean = `Task.where(title: "${title}").delete_all`
    cy.task('railsRunner', `${clean}; Project.first.tasks.create!(title: "${title}", due_date: Date.yesterday)`)

    ;[[1440, 900, 560], [390, 844, 358]].forEach(([viewportWidth, viewportHeight, panelWidth]) => {
      cy.viewport(viewportWidth, viewportHeight)
      cy.visit('/bali/topbar/inbox/default')
      cy.get(trigger).click()
      cy.wait('@popover')
      cy.get(`${panel} .bali-inbox-popover-row`).contains(title).should('be.visible')
      cy.get(panel).should(($panel) => {
        expect($panel[0].getBoundingClientRect().width, 'panel width').to.equal(panelWidth)
        expect($panel[0].scrollWidth, 'nothing scrolls sideways').to.be.at.most($panel[0].clientWidth)
      })
    })

    cy.task('railsRunner', clean)
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

// #1567 — the open panel hangs off the <body> a Turbo visit replaces. The admin shell has the icon
// in its topbar and a sidebar link to a page whose response the test holds, so the visit stays in
// progress (`aria-busy` on <html>) for as long as the test needs.
describe('Topbar inbox across a Turbo visit', () => {
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const trigger = 'a.bali-topbar-inbox-trigger'
  const panel = '#bali-inbox-panel'
  const destination = '/admin/studios'
  let release

  const holdDestination = () => {
    release = null
    cy.intercept({ method: 'GET', pathname: destination }, (req) =>
      new Promise((resolve) => { release = resolve }).then(() => req.continue())
    )
  }
  const releaseDestination = () =>
    cy.wrap(null).should(() => expect(release, 'the held request').to.be.a('function')).then(() => release())

  // The element's own `click()`: no pointer crosses the link, so Turbo's `mouseenter` prefetch sends
  // no second request for the hold to catch.
  const followSidebarLink = (path) => cy.get(`a[href="${path}"]:visible`).first().then(($link) => $link[0].click())

  const visitEnded = (path) => {
    cy.location('pathname').should('eq', path)
    cy.get('html[aria-busy]').should('not.exist')
  }

  beforeEach(() => {
    cy.intercept('GET', '**/inbox/popover*').as('popover')
  })

  it('a panel opened while the visit loads is open on the page it brings', () => {
    cy.visit(`${appOrigin}/admin`)
    holdDestination()
    followSidebarLink(destination)
    cy.get('html[aria-busy]').should('exist')

    cy.get(trigger).click()
    cy.get(trigger).should('have.attr', 'aria-expanded', 'true')
    releaseDestination()

    visitEnded(destination)
    cy.get(trigger).should('have.attr', 'aria-expanded', 'true')
    cy.get(panel).should('be.visible')
    cy.get(`${panel} .bali-inbox-popover-row`).should('have.length.at.least', 1)
  })

  // Turbo paints the cached page first and then the response: two renders, two controllers.
  it('a panel opened before the cached preview paints is open once the response replaces it', () => {
    cy.visit(`${appOrigin}${destination}`)
    followSidebarLink('/admin')
    visitEnded('/admin')
    holdDestination()

    cy.get(trigger).then(($trigger) => {
      const doc = $trigger[0].ownerDocument
      doc.querySelector(`a[href="${destination}"]`).click()
      expect(doc.documentElement.hasAttribute('aria-busy'), 'the visit has started').to.equal(true)
      expect(doc.documentElement.hasAttribute('data-turbo-preview'), 'the preview has not painted yet').to.equal(false)
      $trigger[0].click()
    })
    cy.get('html[data-turbo-preview]').should('exist')
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    releaseDestination()

    visitEnded(destination)
    cy.get('html[data-turbo-preview]').should('not.exist')
    cy.get(trigger).should('have.attr', 'aria-expanded', 'true')
    cy.get(panel).should('be.visible')
  })

  it('a panel opened and closed while the visit loads stays closed', () => {
    cy.visit(`${appOrigin}/admin`)
    holdDestination()
    followSidebarLink(destination)
    cy.get('html[aria-busy]').should('exist')

    cy.get(trigger).click()
    cy.get(trigger).should('have.attr', 'aria-expanded', 'true')
    cy.get(trigger).click()
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    releaseDestination()

    visitEnded(destination)
    // Long enough for an open on `turbo:load` to have shown the panel.
    cy.wait(300)
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get('[data-tippy-root]').should('not.exist')
  })

  // The row's link renders the next page while the panel is still open.
  it('a panel opened on a loaded page arrives closed on the page one of its rows leads to', () => {
    cy.visit(`${appOrigin}/admin`)
    cy.get(trigger).click()
    cy.wait('@popover')
    cy.get(`${panel} .bali-inbox-popover-row`).first().click()

    visitEnded('/admin/projects/1')
    cy.get(trigger).should('exist')
    cy.wait(300)
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get('[data-tippy-root]').should('not.exist')
  })

  // The row's visit cancels the held one; a click inside the panel never goes through `close()`.
  it('a panel opened while one visit loads arrives closed on the page a row leads to instead', () => {
    cy.visit(`${appOrigin}/admin`)
    holdDestination()
    followSidebarLink(destination)
    cy.get('html[aria-busy]').should('exist')
    cy.get(trigger).click()
    cy.wait('@popover')

    cy.get(`${panel} .bali-inbox-popover-row`).first().click()
    releaseDestination()

    visitEnded('/admin/projects/1')
    cy.get(trigger).should('exist')
    cy.wait(300)
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get('[data-tippy-root]').should('not.exist')
  })

  // Brought over by the visit, it is now the panel of a loaded page.
  it('a panel the visit brought arrives closed on the page one of its rows leads to', () => {
    cy.visit(`${appOrigin}/admin`)
    holdDestination()
    followSidebarLink(destination)
    cy.get('html[aria-busy]').should('exist')
    cy.get(trigger).click()
    releaseDestination()
    visitEnded(destination)
    cy.get(`${panel} .bali-inbox-popover-row`).should('have.length.at.least', 1)

    cy.get(`${panel} .bali-inbox-popover-row`).first().click()

    visitEnded('/admin/projects/1')
    cy.get(trigger).should('exist')
    cy.wait(300)
    cy.get(trigger).should('have.attr', 'aria-expanded', 'false')
    cy.get('[data-tippy-root]').should('not.exist')
  })

  // A host that loads tippy.js as a module of its own (an importmap) can have a render replace the
  // page while `open()` waits for it. The dummy bundles tippy.js, so the element leaves in the same
  // task as the click, before the import resolves.
  it('an open whose element leaves the page before tippy.js arrives does not go to the full page', () => {
    cy.visit(`${appOrigin}/admin`)
    cy.intercept({ method: 'GET', pathname: '/inbox' }).as('fullPage')

    cy.get(trigger).then(($trigger) => {
      $trigger[0].click()
      $trigger[0].closest('[data-controller~="topbar-inbox"]').remove()
    })

    // Long enough for `location.assign` to have left.
    cy.wait(500)
    cy.get('@fullPage.all').should('have.length', 0)
    cy.location('pathname').should('eq', '/admin')
  })
})
