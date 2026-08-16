// #1041 — the FeedbackWidget's screen capture and panel alignment already have
// specs; the two halves that talk to the host's server did not. Both are
// invisible from the markup: the unread badge is a poll the controller runs on
// its own, and the embed credential is handed over by `postMessage` after the
// frame loads, deliberately NOT in the frame's URL.
describe('FeedbackWidget handshake', () => {
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  const badgeUrl = 'https://opina-demo.example.com/api/v1/projects/demo-project/badge'
  const badge = () => cy.get('[data-feedback-widget-target="badge"]')

  // The badge lives on another origin, so a stubbed response still has to say
  // it may be read or the fetch rejects before the controller sees it.
  const stubBadge = (body, statusCode = 200) =>
    cy.intercept('GET', `${badgeUrl}*`, {
      statusCode,
      headers: { 'access-control-allow-origin': '*' },
      body
    }).as('badge')

  const stubEmbed = () =>
    cy.intercept('GET', 'https://opina-demo.example.com/embed/**', {
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
      expectInEmbed('#query-string', '(empty)')
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
      expectInEmbed('#query-string', '(empty)')
      cy.get('#feedback-widget iframe').then(($frame) => {
        $frame[0].contentDocument.querySelector('#go-deeper').click()
      })
      expectInEmbed('#query-string', 'paso=2')

      cy.get('#feedback-widget [data-action="drawer#close"]').click()
      cy.get('#feedback-widget').should('not.have.class', 'drawer-open')

      cy.get('[data-action="feedback-widget#open"]').click()

      // A fresh frame, back at the embed's front page — and the token goes out
      // again, because this document has never seen it.
      expectInEmbed('#query-string', '(empty)')
      expectInEmbed('#received-token', 'demo-token-123')
    })
  })
})
