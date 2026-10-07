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

    // A `showModal()`-ed <dialog> hands the focus back by itself on `close()`, so the test
    // above passes without the controller's own restore. Only `_showOverlay`'s fallback,
    // where the panel opens by its class alone, leaves the restore to the controller.
    it('returns the focus to whatever held it before when the panel opens without showModal()', () => {
      cy.window().then(win => { win.HTMLDialogElement.prototype.showModal = undefined })
      cy.get('body').then($body => {
        const probe = $body[0].ownerDocument.createElement('button')
        probe.id = 'opener-probe'
        probe.textContent = 'open'
        $body[0].prepend(probe)
        probe.focus()
      })

      openWith('<input id="loaded-field" autofocus>')
      cy.focused().should('have.id', 'loaded-field')
      cy.get('[data-modal-target="template"]').should($dialog => {
        expect($dialog[0].classList.contains('modal-open'), 'open').to.equal(true)
        expect($dialog[0].matches(':modal'), 'in the top layer').to.equal(false)
      })

      cy.focused().type('{esc}')
      cy.get('.modal-open').should('not.exist')
      cy.document().should(doc => {
        expect(doc.activeElement.id, 'the focused element').to.equal('opener-probe')
      })
    })

    it('keeps Tab inside the panel while the skeleton shows', () => {
      openWith(null)

      cy.focused().trigger('keydown', { key: 'Tab' })
      cy.focused().should($el => {
        expect($el.closest('[data-modal-target="wrapper"]')).to.have.length(1)
      })
    })

    // The panel's last stop, as the trap has to see it. Left out of the trap, a summary, an
    // editable region or a player was skipped: Tab from the field before it wrapped to the ✕.
    // Counted in, a disabled Save let Tab out of the overlay from the Cancel before it.
    ;[
      ['the summary of a details', '<details><summary id="last">More</summary><p>Detail</p></details>'],
      ['an editable region', '<div id="last" contenteditable="true">Notes</div>'],
      ['an audio player', '<audio id="last" controls></audio>'],
      ['a video player', '<video id="last" controls></video>'],
      ['the Cancel before a disabled Save', '<button id="last" type="button">Cancel</button><button type="submit" disabled>Save</button>']
    ].forEach(([what, html]) => {
      it(`wraps Shift+Tab from the ✕ to ${what} at the end of the panel`, () => {
        openWith(`<input id="first-field">${html}`)
        cy.focused().should('have.attr', 'aria-label')

        cy.focused().trigger('keydown', { key: 'Tab', shiftKey: true })
        cy.focused().should('have.id', 'last')
      })
    })
  })

  // A panel rendered `active:` is opened by its controller's `connect`, with no trigger.
  // Left to `showModal()`, the focus went to the panel itself, the first element in it
  // carrying a tabindex.
  context('focus of a panel rendered open', () => {
    [
      { path: '/bali/modal/default', firstControl: '.modal-box > button[data-action="modal#close"]' },
      { path: '/bali/drawer/default', firstControl: '.drawer-header > button[data-action="drawer#close"]' }
    ].forEach(({ path, firstControl }) => {
      it(`goes to the first control, as when opened from a trigger: ${path}`, () => {
        cy.visit(path)

        cy.focused().should('match', firstControl)
      })
    })
  })

  // With no trigger to go back to, closing left the focus on <body>: in AppLayout, whose
  // panels sit at the end of <main>, the next Tab went to the skip link at the top of the page.
  context('focus after closing a panel no click opened', () => {
    it('goes to <main> when the panel was rendered open', () => {
      cy.visit('/bali/app_layout/drawer_opened_by_the_server')
      cy.focused().should('have.id', 'project_name')

      cy.focused().type('{esc}')
      cy.get('#new-project-drawer').should('not.have.class', 'drawer-open')
      cy.focused().should('match', 'main#main-content')
    })

    // In a browser the field's `autofocus` takes the focus on page load, before the
    // controller connects, and leaves nothing outside the panel to remember. Cypress's frame
    // does not run `autofocus`, so the field takes it by hand as the replaced panel connects.
    it('goes to <main> when the focus was in the panel before its controller connected', () => {
      cy.visit('/bali/app_layout/drawer_opened_by_the_server')
      cy.focused().should('have.id', 'project_name')

      cy.get('#new-project-drawer').then(([dialog]) => {
        const replaced = dialog.cloneNode(true)
        replaced.removeAttribute('open')
        replaced.setAttribute('data-replaced', '')
        dialog.replaceWith(replaced)
        replaced.querySelector('#project_name').focus()
      })
      cy.get('#new-project-drawer[data-replaced]').should('have.attr', 'open')
      cy.focused().should('have.id', 'project_name')

      cy.focused().type('{esc}')
      cy.get('#new-project-drawer').should('not.have.class', 'drawer-open')
      cy.focused().should('match', 'main#main-content')
    })

    const openEvents = [
      { event: 'bali:drawer:open', panel: 'main-drawer', openClass: 'drawer-open' },
      { event: 'bali:modal:open', panel: 'main-modal', openClass: 'modal-open' }
    ]
    openEvents.forEach(({ event, panel, openClass }) => {
      it(`goes to <main> when an open event opened it: ${event}`, () => {
        cy.visit('/bali/app_layout/default')
        cy.document().then(doc => {
          doc.dispatchEvent(new CustomEvent(event, { detail: { id: panel, content: null, options: {} } }))
        })
        cy.focused().should($el => expect($el.closest(`#${panel}`)).to.have.length(1))

        cy.focused().type('{esc}')
        cy.get(`#${panel}`).should('not.have.class', openClass)
        cy.focused().should('match', 'main#main-content')
      })
    })

    // Removed while its panel was open — not by the stream of a submit, which lands the frame
    // after the close and finds the focus already back on it.
    it('goes to <main> when the trigger that opened it is gone', () => {
      cy.visit('/bali/app_layout/overlay_triggers')
      cy.get('[data-testid="topbar-drawer-trigger"]').click()
      cy.get('#main-drawer').should($dialog => {
        expect($dialog[0].matches(':modal'), 'open').to.equal(true)
        expect($dialog.text(), 'the fetched content').to.include('John Doe')
      })

      cy.get('[data-testid="topbar-drawer-trigger"]').then(([trigger]) => trigger.remove())
      cy.focused().type('{esc}')
      cy.get('#main-drawer').should('not.have.class', 'drawer-open')
      cy.focused().should('match', 'main#main-content')
    })

    // A Turbo Stream that replaces the panel with an open one: what held the focus then is
    // still where the reader was. No `id` on it: Turbo hands the focus back to an element
    // with one once a stream has rendered, and here that is a control the panel blocks.
    it('goes back to what held it when a stream put the panel there open', () => {
      cy.visit('/bali/app_layout/default')
      cy.get('main').then(([main]) => {
        main.insertAdjacentHTML('afterbegin', '<button data-testid="opener-probe">Save</button>')
        main.querySelector('[data-testid="opener-probe"]').focus()
      })

      cy.window().then(win => {
        const opened = win.document.getElementById('main-drawer').cloneNode(true)
        opened.classList.add('drawer-open')
        opened.removeAttribute('inert')
        opened.setAttribute('data-streamed', '')
        win.Turbo.renderStreamMessage(
          `<turbo-stream action="replace" target="main-drawer"><template>${opened.outerHTML}</template></turbo-stream>`
        )
      })
      cy.get('#main-drawer[data-streamed]').should('have.attr', 'open')

      cy.focused().type('{esc}')
      cy.get('#main-drawer').should('not.have.class', 'drawer-open')
      cy.focused().should('have.attr', 'data-testid', 'opener-probe')
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
