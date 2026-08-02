describe('ModalController', () => {
  context('form modal', () => {
    beforeEach(() => {
      cy.visit('/bali/modal/form_modal')
    })

    it('stays open when a synthetic keydown fires (browser autocomplete)', () => {
      // Verify modal is visible
      cy.get('.modal-open').should('exist')
      cy.get('.modal-box input#name').should('be.visible')

      // Focus the input and type something
      cy.get('.modal-box input#name').click().type('test')

      // Simulate what browsers do when selecting an autocomplete suggestion:
      // a keydown event with key: undefined is dispatched on the input
      cy.get('.modal-box input#name').then($input => {
        $input[0].dispatchEvent(new Event('keydown', { bubbles: true, cancelable: true }))
      })

      // Modal should still be open
      cy.get('.modal-open').should('exist')
      cy.get('.modal-box input#name').should('be.visible')
    })

    it('closes when pressing Escape key', () => {
      cy.get('.modal-open').should('exist')

      // Press Escape key
      cy.get('.modal-box input#name').type('{esc}')

      // Modal should be closed
      cy.get('.modal-open').should('not.exist')
    })

    it('stays open when clicking inside the modal box', () => {
      cy.get('.modal-open').should('exist')

      // Click on the input inside the modal
      cy.get('.modal-box input#name').click()

      // Modal should still be open
      cy.get('.modal-open').should('exist')
    })
  })

  // `/bali/modal/default` renders no header slot, so it gets the standalone ✕ —
  // the same shape as the shared `#main-modal`, where the ✕ is the first
  // focusable inside the panel. That is what used to steal the focus.
  context('focus', () => {
    const openWith = (content) =>
      cy.window().then(win => {
        win.document.dispatchEvent(
          new win.CustomEvent('bali:modal:open', { detail: { content, options: {} } })
        )
      })

    beforeEach(() => {
      cy.visit('/bali/modal/default?active=false')
      cy.get('[data-modal-target="template"]').should('not.have.class', 'modal-open')
    })

    it('gives the focus to the content autofocus, not to the close button', () => {
      openWith('<button id="decoy">decoy</button><input id="wants-focus" autofocus>')

      cy.get('.modal-open').should('exist')
      cy.focused().should('have.id', 'wants-focus')
    })

    it('falls back to the first focusable when the content has no autofocus', () => {
      openWith('<input id="first-field"><input id="second-field">')

      // The standalone ✕ precedes the content inside the panel, so it legitimately
      // wins when nothing asked for the focus.
      cy.focused().should('have.attr', 'aria-label')
    })

    // The skeleton phase: `open()` shows the panel with content: null while the
    // fetch is in flight. Focus used to stay on the trigger — a sibling subtree —
    // so Escape never reached the panel's handler for the whole length of the fetch.
    it('holds the focus inside the panel while the skeleton shows, so Escape closes', () => {
      openWith(null)

      cy.get('.modal-open').should('exist')
      cy.focused().should($el => {
        expect($el.closest('[data-modal-target="wrapper"]')).to.have.length(1)
      })

      cy.focused().type('{esc}', { force: true })
      cy.get('.modal-open').should('not.exist')
    })

    // `openModal` runs twice per open — skeleton, then content — and now that the
    // skeleton takes the focus, the second run must not record the panel as the
    // element to hand the focus back to on close.
    it('returns the focus to whatever held it before, not to the panel', () => {
      cy.get('body').then($body => {
        const probe = $body[0].ownerDocument.createElement('button')
        probe.id = 'opener-probe'
        probe.textContent = 'open'
        $body[0].prepend(probe)
        probe.focus()
      })

      openWith(null)
      openWith('<input id="loaded-field" autofocus>')
      cy.focused().should('have.id', 'loaded-field')

      cy.focused().type('{esc}')
      cy.get('.modal-open').should('not.exist')
      cy.focused().should('have.id', 'opener-probe')
    })

    it('keeps Tab inside the panel while the skeleton shows', () => {
      openWith(null)

      cy.focused().trigger('keydown', { key: 'Tab' })
      cy.focused().should($el => {
        expect($el.closest('[data-modal-target="wrapper"]')).to.have.length(1)
      })
    })
  })

  // The trigger-driven path, which the previews cannot exercise because they
  // render a modal that is already open. This page lives in the dummy app rather
  // than under the Lookbook preview path `baseUrl` points at, so the origin is
  // derived from it rather than written out.
  context('abandoning an open while it loads', () => {
    const appOrigin = new URL(Cypress.config('baseUrl')).origin

    it('does not reopen when the response lands after the user pressed Escape', () => {
      // Hold the response open long enough for the skeleton phase to be real.
      cy.intercept('GET', '**/characters/new*', req => {
        req.on('response', res => res.setDelay(2000))
      }).as('newCharacter')

      cy.visit(`${appOrigin}/movies/1`)
      // The trigger lives in the Characters tab, which starts collapsed.
      cy.get('[role="tab"]').contains('Characters').click()
      cy.get('a[data-action*="modal#open"]').should('be.visible').click()

      // Skeleton is up and the focus is inside the panel — which is what lets
      // Escape reach the panel's handler at all.
      cy.get('.modal-open').should('exist')
      cy.focused().should($el => {
        expect($el.closest('[data-modal-target="wrapper"]')).to.have.length(1)
      })

      cy.focused().type('{esc}', { force: true })
      cy.get('.modal-open').should('not.exist')

      // The abandoned response arrives; the modal must stay shut.
      cy.wait('@newCharacter')
      cy.wait(500)
      cy.get('.modal-open').should('not.exist')
    })
  })

  // Lets a page carrying more than one overlay open the one it means. An event
  // without an id stays a broadcast, which is what every existing call site sends.
  context('addressed open events', () => {
    beforeEach(() => {
      cy.visit('/bali/modal/default?active=false')
      cy.get('[data-modal-target="template"]').should('not.have.class', 'modal-open')
    })

    const dispatchWithId = (id) =>
      cy.window().then(win => {
        win.document.dispatchEvent(
          new win.CustomEvent('bali:modal:open', {
            detail: { id, content: '<p id="addressed">hi</p>', options: {} }
          })
        )
      })

    it('ignores an event addressed to another modal', () => {
      dispatchWithId('some-other-modal')
      cy.get('.modal-open').should('not.exist')
    })

    it('opens when the event names this modal', () => {
      cy.get('[data-modal-target="template"]')
        .invoke('attr', 'id')
        .then(id => dispatchWithId(id))

      cy.get('.modal-open').should('exist')
      cy.get('#addressed').should('exist')
    })
  })
})
