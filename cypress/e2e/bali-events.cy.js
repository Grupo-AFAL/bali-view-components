// Guards the public event contract: every event the package emits or listens for is
// `bali:<component>:<event>`.
//
// A renamed event is the one breaking change that produces no error — no exception, no
// console warning, no failing render. The listener just stops running. These specs exist so
// the next rename fails here instead of in a host's browser, which is why each one also
// asserts the v2 name is *not* honoured any more.
describe('Bali public events', () => {
  const dispatchOn = (win, target, type, detail) => {
    win[target].dispatchEvent(new win.CustomEvent(type, { detail }))
  }

  context('bali:modal:open', () => {
    beforeEach(() => {
      cy.visit('/bali/modal/default?active=false')
      cy.get('[data-modal-target="template"]').should('not.have.class', 'modal-open')
    })

    it('opens the modal and injects detail.content', () => {
      cy.window().then(win => {
        dispatchOn(win, 'document', 'bali:modal:open', {
          content: '<p id="dispatched-content">from the event</p>',
          options: {}
        })
      })

      cy.get('.modal-open').should('exist')
      cy.get('#dispatched-content').should('have.text', 'from the event')
    })

    it('ignores the v2 name openModal', () => {
      cy.window().then(win => {
        dispatchOn(win, 'document', 'openModal', { content: '<p>legacy</p>', options: {} })
      })

      cy.get('.modal-open').should('not.exist')
    })
  })

  context('bali:drawer:open', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/default?active=false')
      cy.get('[data-drawer-target="template"]').should('not.have.class', 'drawer-open')
    })

    it('opens the drawer and injects detail.content', () => {
      cy.window().then(win => {
        dispatchOn(win, 'document', 'bali:drawer:open', {
          content: '<p id="dispatched-content">from the event</p>',
          options: {}
        })
      })

      cy.get('.drawer-open').should('exist')
      cy.get('#dispatched-content').should('have.text', 'from the event')
    })

    it('ignores the v2 name openDrawer', () => {
      cy.window().then(win => {
        dispatchOn(win, 'document', 'openDrawer', { content: '<p>legacy</p>', options: {} })
      })

      cy.get('.drawer-open').should('not.exist')
    })
  })

  context('bali:modal:success', () => {
    it('fires on a successful submit — and the v2 modal:success does not', () => {
      cy.visit('/bali/drawer/turbo_stream_form')

      cy.intercept('POST', '/fake/submit*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: `
          <turbo-stream action="append" target="stream-target">
            <template><p id="stream-result">It worked</p></template>
          </turbo-stream>
        `
      }).as('submit')

      const seen = []
      cy.window().then(win => {
        win.document.addEventListener('bali:modal:success', () => seen.push('new'))
        win.document.addEventListener('modal:success', () => seen.push('legacy'))
      })

      cy.get('[data-action="drawer#submit"]').click()
      cy.wait('@submit')
      cy.get('#stream-result').should('exist')

      // The drawer inherits `submit` from the modal, so it emits the modal's name —
      // there is deliberately no bali:drawer:success.
      cy.wrap(seen).should('deep.equal', ['new'])
    })
  })

  context('bali:command:select', () => {
    it('fires when an item without an href is activated', () => {
      cy.visit('/bali/command/default')
      cy.get('[data-controller="command"]', { timeout: 5000 }).should('exist')

      const seen = []
      cy.window().then(win => {
        win.addEventListener('bali:command:select', e => seen.push(e.detail.value))
      })

      cy.get('body').type('{meta+k}')

      // Every row in this preview navigates; the event is the other branch, for an
      // item a host wired to an action instead of a URL.
      cy.get('[data-command-target="row"]:not(.hidden)').first().then($row => {
        $row.removeAttr('data-href')
        $row.attr('data-value', 'chosen')
      })
      cy.get('[data-command-target="row"]:not(.hidden)').first().click()

      cy.wrap(seen).should('deep.equal', ['chosen'])
      cy.get('[data-command-target="panel"]').should('have.class', 'hidden')
    })
  })
})
