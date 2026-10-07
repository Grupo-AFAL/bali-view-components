// #1041 — the FeedbackWidget's screen capture and panel alignment already have
// specs; the two halves that talk to the host's server did not. Both are
// invisible from the markup: the unread badge is a poll the controller runs on
// its own, and the embed credential is handed over by `postMessage` after the
// frame loads, deliberately NOT in the frame's URL.
describe('FeedbackWidget handshake', () => {
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  // The previews point the widget at the dummy app, which stands in for Opina.
  const badgeUrl = `${appOrigin}/api/v1/projects/demo-project/badge`
  const badge = () => cy.get('[data-feedback-widget-target="badge"]')

  const stubBadge = (body, statusCode = 200) =>
    cy.intercept('GET', `${badgeUrl}*`, { statusCode, body }).as('badge')

  const stubEmbed = () =>
    cy.intercept('GET', `${appOrigin}/embed/**`, {
      statusCode: 200,
      headers: { 'content-type': 'text/html' },
      body: '<html><body>embed</body></html>'
    }).as('embed')

  describe('unread badge', () => {
    it('asks the host for the count as soon as it connects', () => {
      stubBadge({ unread_count: 3 })
      cy.visit('/bali/feedback_widget/default')

      cy.wait('@badge').its('request.url').should('include', 'since=')
      badge().should('not.have.class', 'hidden')
      badge().should('have.text', '3')
    })

    it('stays out of the way when there is nothing unread', () => {
      stubBadge({ unread_count: 0 })
      cy.visit('/bali/feedback_widget/default')

      cy.wait('@badge')
      badge().should('have.class', 'hidden')
    })

    it('looks back a week the first time it asks', () => {
      cy.clock(Date.now(), ['setInterval', 'clearInterval', 'Date'])
      stubBadge({ unread_count: 1 })
      cy.visit('/bali/feedback_widget/default')

      cy.wait('@badge').then((interception) => {
        const since = new Date(new URL(interception.request.url).searchParams.get('since'))
        const days = (Date.now() - since.getTime()) / (24 * 60 * 60 * 1000)

        expect(days, 'days looked back').to.be.closeTo(7, 0.5)
      })
    })

    it('keeps asking on the interval it was given', () => {
      cy.clock(Date.now(), ['setInterval', 'clearInterval', 'Date'])
      stubBadge({ unread_count: 2 })
      cy.visit('/bali/feedback_widget/default')

      cy.wait('@badge')
      cy.get('@badge.all').should('have.length', 1)

      // The preview's interval is the 5 minute default.
      cy.tick(300000)

      cy.get('@badge.all').should('have.length', 2)
    })

    it('says nothing when the host answers with an error', () => {
      stubBadge('', 500)
      cy.visit('/bali/feedback_widget/default')

      cy.wait('@badge')
      // A failed poll is not news: the badge keeps whatever it had, and the
      // page must not break over it.
      badge().should('have.class', 'hidden')
      cy.get('[data-action="feedback-widget#open"]').should('be.visible')
    })

    it('clears the badge when the panel is opened', () => {
      stubBadge({ unread_count: 4 })
      stubEmbed()
      cy.visit('/bali/feedback_widget/default')

      cy.wait('@badge')
      badge().should('have.text', '4')

      cy.get('[data-action="feedback-widget#open"]').click()

      // Whatever was unread is being read right now.
      badge().should('have.class', 'hidden')
      cy.get('#feedback-widget').should('have.class', 'drawer-open')
    })

    // The count Opina had before the panel was opened, answered after it: the panel has
    // just made it zero.
    it('does not bring back a count asked for before the panel was opened', () => {
      let asked = false
      let answer
      const opened = new Promise((resolve) => { answer = resolve })
      cy.intercept('GET', `${badgeUrl}*`, (req) => {
        asked = true
        return opened.then(() => req.reply({ statusCode: 200, body: { unread_count: 5 } }))
      }).as('badge')
      stubEmbed()
      cy.visit('/bali/feedback_widget/default')
      cy.wrap(null).should(() => expect(asked, 'count requested').to.equal(true))

      cy.get('[data-action="feedback-widget#open"]').click()
      cy.get('#feedback-widget').should('have.class', 'drawer-open')
      cy.then(() => answer())
      // Time for the answer to land, had it still been awaited.
      cy.wait(500)

      badge().should('have.class', 'hidden')
      cy.get('#feedback-widget-unread').should('have.text', '')
    })

    // The same cap `Bali::Topbar::IconAction` draws: the two badges sit side by side in the
    // Topbar. The description keeps the real number.
    it('caps the count at 99+, as the Topbar icon actions do', () => {
      stubBadge({ unread_count: 128 })
      cy.visit('/bali/feedback_widget/default')

      badge().should('have.text', '99+')
      cy.get('#feedback-widget-unread').should('have.text', '128 unread')
    })

    it('shows a count at the cap as it is', () => {
      stubBadge({ unread_count: 99 })
      cy.visit('/bali/feedback_widget/default')

      badge().should('have.text', '99')
    })
  })

  // Opina keeps what has been read, per user: the badge asks with the widget's token and
  // opening the panel tells it so. Without that the count lived in this page's memory, and
  // came back on the next page load.
  describe('read state', () => {
    const readUrl = `${badgeUrl}/read`
    const token = () => cy.get('[data-feedback-widget-token-value]')
      .invoke('attr', 'data-feedback-widget-token-value')
    const open = () => cy.get('[data-action="feedback-widget#open"]').click()

    const stubRead = (reply = { statusCode: 204 }) =>
      cy.intercept('POST', readUrl, reply).as('read')

    it('asks for the count with the token as a Bearer header, never in the URL', () => {
      stubBadge({ unread_count: 3 })
      cy.visit('/bali/feedback_widget/default')

      token().then((jwt) => {
        cy.wait('@badge').then(({ request }) => {
          expect(request.headers.authorization).to.equal(`Bearer ${jwt}`)
          expect(request.url).to.not.include(jwt)
        })
      })
    })

    it('tells Opina when the panel is opened, with the same Bearer', () => {
      stubBadge({ unread_count: 3 })
      stubRead()
      stubEmbed()
      cy.visit('/bali/feedback_widget/default')
      cy.wait('@badge')

      open()

      token().then((jwt) => {
        cy.wait('@read').then(({ request }) => {
          expect(request.headers.authorization).to.equal(`Bearer ${jwt}`)
        })
      })
    })

    // The token lasts `token_expires_in`, so a tab left open long enough gets a 401. The
    // number it was showing can no longer be refreshed, so it goes, and so does the polling.
    it('hides the count and stops asking once Opina stops accepting the token', () => {
      cy.clock(Date.now(), ['setInterval', 'clearInterval', 'Date'])
      let expired = false
      cy.intercept('GET', `${badgeUrl}*`, (req) => {
        req.reply(expired
          ? { statusCode: 401 }
          : { statusCode: 200, body: { unread_count: 3 } })
      }).as('badge')
      cy.visit('/bali/feedback_widget/default')
      badge().should('have.text', '3').and('not.have.class', 'hidden')

      cy.then(() => { expired = true })
      cy.tick(300000)

      cy.get('@badge.all').should('have.length', 2)
      badge().should('have.class', 'hidden')
      cy.get('#feedback-widget-unread').should('have.text', '')

      cy.tick(300000)
      // Nothing to wait for when no request goes out.
      cy.wait(500)
      cy.get('@badge.all').should('have.length', 2)
    })

    // An Opina that does not keep read state has no such route, and a request that never
    // arrives is no worse: the badge is cleared for this page either way.
    it('says nothing when the read request fails', () => {
      stubBadge({ unread_count: 3 })
      stubRead({ forceNetworkError: true })
      stubEmbed()
      cy.visit('/bali/feedback_widget/default')
      badge().should('have.text', '3')

      open()

      cy.wait('@read')
      badge().should('have.class', 'hidden')
      cy.get('#feedback-widget').should('have.class', 'drawer-open')
    })

    // One controller drives all three triggers, and the count is read out from the
    // description, since the number in the badge is hidden from assistive technology.
    ;['default', 'topbar_icon', 'topbar_labeled'].forEach((preview) => {
      it(`shows and announces the count on the ${preview} trigger, and clears both on open`, () => {
        stubBadge({ unread_count: 3 })
        stubRead()
        stubEmbed()
        cy.visit(`/bali/feedback_widget/${preview}`)

        badge().should('have.text', '3').and('not.have.class', 'hidden')
        cy.get('[data-action="feedback-widget#open"]')
          .invoke('attr', 'aria-describedby')
          .then((id) => cy.get(`#${id}`).should('have.text', '3 unread'))

        open()

        badge().should('have.class', 'hidden')
        cy.get('#feedback-widget-unread').should('have.text', '')
      })
    })
  })

  // The page loads light and the theme is switched in place, as the UserMenu's switch
  // does: the scheme is read when the panel opens, not when the widget connects.
  describe('colour scheme', () => {
    const expectScheme = (setUp, scheme) => {
      stubBadge({ unread_count: 0 })
      stubEmbed()
      cy.visit('/bali/feedback_widget/default')
      cy.document().then((doc) => setUp(doc.documentElement))

      cy.get('[data-action="feedback-widget#open"]').click()

      cy.wait('@embed').then(({ request }) => {
        expect(new URL(request.url).searchParams.get('color_scheme')).to.equal(scheme)
      })
    }

    const themes = {
      light: 'light',
      dark: 'dark',
      afal: 'light',
      'afal-dark': 'dark',
      'costa-norte': 'light',
      'costa-norte-dark': 'dark'
    }

    Object.entries(themes).forEach(([theme, scheme]) => {
      it(`asks for a ${scheme} embed under ${theme}`, () => {
        expectScheme((html) => html.setAttribute('data-theme', theme), scheme)
      })
    })

    // No Bali theme declares either, but a host's own CSS can.
    it('asks for a dark embed under color-scheme: only dark', () => {
      expectScheme((html) => { html.style.colorScheme = 'only dark' }, 'dark')
    })

    // `light dark` hands the choice to the operating system, so the test makes that one dark:
    // with the runner's light default, following the OS would pass unnoticed.
    describe('with the operating system in dark mode', () => {
      const emulate = (features) => Cypress.automation('remote:debugger:protocol', {
        command: 'Emulation.setEmulatedMedia',
        params: { features }
      })

      beforeEach(() => cy.then(() => emulate([{ name: 'prefers-color-scheme', value: 'dark' }])))
      afterEach(() => cy.then(() => emulate([])))

      it('asks for a light embed under color-scheme: light dark', () => {
        expectScheme((html) => {
          expect(html.ownerDocument.defaultView.matchMedia('(prefers-color-scheme: dark)').matches,
            'operating system in dark mode').to.equal(true)
          html.style.colorScheme = 'light dark'
        }, 'light')
      })
    })
  })

  describe('embed credential', () => {
    // The dummy's stand-in embed is served by the app itself, so the frame is
    // same-origin here and its document can be read. In production it is Opina
    // and it cannot — which is what the message protocol is for.
    const expectInEmbed = (selector, expected) =>
      cy.get('#feedback-widget iframe').should(($frame) => {
        const element = $frame[0].contentDocument.querySelector(selector)

        expect(element, selector).to.not.equal(null)
        expect(element.textContent, selector).to.equal(expected)
      })

    beforeEach(() => {
      cy.viewport(1280, 900)
      cy.visit(`${appOrigin}/feedback-widget-demo`)
      cy.get('[data-action="feedback-widget#open"]').click()
      cy.get('#feedback-widget').should('have.class', 'drawer-open')
    })

    it('sends the token by message and never in the URL', () => {
      // A URL is the one place a bearer credential must not travel: access
      // logs, `Referer` headers and browser history all keep a copy.
      expectInEmbed('#query-string', 'color_scheme=light')
      expectInEmbed('#received-token', 'demo-token-123')
    })

    it('sends it once, not again on every page inside the frame', () => {
      expectInEmbed('#received-token', 'demo-token-123')

      cy.get('#feedback-widget iframe').then(($frame) => {
        $frame[0].contentDocument.querySelector('#go-deeper').click()
      })

      // The embed traded the token for a cookie on the first load; the pages
      // after it are already authenticated, and the context — which every new
      // document does need — arrives all the same.
      expectInEmbed('#host-url', `${appOrigin}/feedback-widget-demo`)
      expectInEmbed('#received-token', '(none)')
    })

    it('reloads the embed on the next opening instead of showing the old one', () => {
      expectInEmbed('#query-string', 'color_scheme=light')
      cy.get('#feedback-widget iframe').then(($frame) => {
        $frame[0].contentDocument.querySelector('#go-deeper').click()
      })
      expectInEmbed('#query-string', 'paso=2')

      cy.get('#feedback-widget [data-action="drawer#close"]').click()
      cy.get('#feedback-widget').should('not.have.class', 'drawer-open')

      cy.get('[data-action="feedback-widget#open"]').click()

      // A fresh frame, back at the embed's front page — and the token goes out
      // again, because this document has never seen it.
      expectInEmbed('#query-string', 'color_scheme=light')
      expectInEmbed('#received-token', 'demo-token-123')
    })
  })
})
