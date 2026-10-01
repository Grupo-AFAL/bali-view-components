import { drag, tap } from '../support/tap'

// #1041 — HoverCard had no E2E spec. Everything it shows is built at runtime:
// tippy is imported on connect, the card is portaled out of the component into
// <body>, and with `hover_url` the content arrives over the network — behind a
// `contentLoaded` flag that has to keep the second hover from asking again.
describe('HoverCard', () => {
  const trigger = () => cy.get('[data-hovercard-target="trigger"]')
  const card = () => cy.get('body > [data-tippy-root]')

  describe('with template content', () => {
    beforeEach(() => {
      cy.visit('/bali/hover_card/default')
    })

    it('shows the template content on hover and hides it on leave', () => {
      card().should('not.exist')

      trigger().trigger('mouseenter')

      card().should('be.visible')
      card().should('contain.text', 'This is the hovercard content')

      trigger().trigger('mouseleave')

      card().should('not.exist')
    })

    it('marks the component active only while the card is up', () => {
      // The class is what a host styles the trigger with; it is not decoration.
      cy.get('.hover-card-component').should('not.have.class', 'is-active')

      trigger().trigger('mouseenter')
      cy.get('.hover-card-component').should('have.class', 'is-active')

      trigger().trigger('mouseleave')
      cy.get('.hover-card-component').should('not.have.class', 'is-active')
    })

    it('announces itself through bali:hovercard events', () => {
      cy.window().then((win) => {
        const seen = []
        win.document.addEventListener('bali:hovercard:show', () => seen.push('show'))
        win.document.addEventListener('bali:hovercard:hide', () => seen.push('hide'))
        cy.wrap(seen).as('events')
      })

      trigger().trigger('mouseenter')
      card().should('be.visible')
      trigger().trigger('mouseleave')
      card().should('not.exist')

      cy.get('@events').should('deep.equal', ['show', 'hide'])
    })

    it('opens on focus, so the keyboard reaches it too', () => {
      trigger().find('button').focus()

      card().should('be.visible')
    })
  })

  describe('with remote content', () => {
    beforeEach(() => {
      cy.intercept('GET', '/show-content-in-hovercard', {
        statusCode: 200,
        body: '<p>Loaded from the server</p>'
      }).as('content')
      cy.visit('/bali/hover_card/with_hover_url')
    })

    it('shows a spinner first and replaces it with the response', () => {
      trigger().trigger('mouseenter')

      card().find('.loading-spinner').should('exist')

      cy.wait('@content')

      card().should('contain.text', 'Loaded from the server')
      card().find('.loading-spinner').should('not.exist')
      // content_padding: true wraps the response, which is what gives the card
      // its inner spacing.
      card().find('.hover-card-content').should('exist')
    })

    it('fetches once, however many times it is opened', () => {
      trigger().trigger('mouseenter')
      cy.wait('@content')
      trigger().trigger('mouseleave')
      card().should('not.exist')

      trigger().trigger('mouseenter')
      card().should('contain.text', 'Loaded from the server')

      cy.get('@content.all').should('have.length', 1)
    })
  })

  describe('with a link as the trigger', () => {
    const link = () => trigger().find('a')
    const destination = '/lookbook/preview/bali/hover_card/default'

    // Read on `document`: after the trigger's own listener, and before Turbo's on
    // `window`, which prevents every click it follows.
    const recordClicks = () => cy.document().then(doc => {
      const prevented = []
      doc.addEventListener('click', e => prevented.push(e.defaultPrevented))
      cy.wrap(prevented).as('prevented')
    })

    // Through the browser's keyboard path, so the link's click carries `detail` 0 as a
    // real Enter's does.
    const pressEnter = () => {
      const key = { key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, nativeVirtualKeyCode: 13 }
      const send = params => Cypress.automation('remote:debugger:protocol', { command: 'Input.dispatchKeyEvent', params })

      return send({ type: 'keyDown', text: '\r', ...key }).then(() => send({ type: 'keyUp', ...key }))
    }

    beforeEach(() => {
      cy.viewport(390, 844)
      cy.visit('/bali/hover_card/link_trigger')
      trigger().should($t => expect($t[0]._tippy, 'tippy mounted').to.exist)
    })

    it('opens the card on the first tap and follows the link on the second', () => {
      recordClicks()

      link().then(tap)
      card().should('be.visible')
      cy.get('@prevented').should('deep.equal', [true])

      link().then(tap)
      cy.location('pathname').should('eq', destination)
    })

    it('lets a tap reach a link inside the card', () => {
      link().then(tap)
      card().find('a').should('be.visible').then(tap)

      cy.location('pathname').should('eq', '/lookbook/preview/bali/hover_card/with_hover_url')
    })

    it('a tap, then Enter, follows the link', () => {
      link().then(tap)
      card().should('be.visible')
      cy.focused().should('match', 'a')

      cy.then(pressEnter)
      cy.location('pathname').should('eq', destination)
    })

    // A drag sets the mark of a touch press and fires no click to use it.
    it('a drag, then Enter, follows the link', () => {
      link().then($a => drag($a, 150))
      link().focus()
      card().should('be.visible')

      cy.then(pressEnter)
      cy.location('pathname').should('eq', destination)
    })

    it('follows the link on the first click with a mouse', () => {
      link().trigger('mouseenter')
      card().should('be.visible')

      link().click()
      cy.location('pathname').should('eq', destination)
    })

    it('follows a mouse click that comes after a drag started on the link', () => {
      link().then($a => drag($a, 150))
      link().trigger('mouseenter')
      card().should('be.visible')

      link().click()
      cy.location('pathname').should('eq', destination)
    })
  })

  describe('opened by click', () => {
    beforeEach(() => {
      cy.visit('/bali/hover_card/default?open_on_click=true')
    })

    it('ignores hover and waits for the click', () => {
      trigger().trigger('mouseenter')
      // Twice tippy's 100ms show duration: were hover still wired, the card
      // would already be up, and asserting its absence would prove nothing.
      cy.wait(200)
      card().should('not.exist')

      trigger().click()

      card().should('be.visible')
    })
  })
})
