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
