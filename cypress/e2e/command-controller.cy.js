describe('CommandController', () => {
  beforeEach(() => {
    cy.visit('/bali/command/default')
    cy.get('[data-controller="command"]', { timeout: 5000 }).should('exist')
  })

  context('opening and closing', () => {
    it('opens via the trigger slot and focuses the input', () => {
      cy.get('[data-action*="click->command#open"] button').click()

      cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')
      cy.get('[data-command-target="backdrop"]').should('not.have.class', 'hidden')
      cy.get('[data-command-target="input"]').should('be.focused')
    })

    it('opens via Cmd/Ctrl+K and closes via the same chord when open', () => {
      // Open
      cy.get('body').type('{meta+k}')
      cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')

      // Close (controller handles both meta and ctrl)
      cy.get('body').type('{meta+k}')
      cy.get('[data-command-target="panel"]').should('have.class', 'hidden')
    })

    it('closes via Escape', () => {
      cy.get('body').type('{meta+k}')
      cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')

      cy.get('[data-command-target="input"]').type('{esc}')
      cy.get('[data-command-target="panel"]').should('have.class', 'hidden')
    })

    it('closes when the backdrop is clicked', () => {
      cy.get('body').type('{meta+k}')
      cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')

      // The panel sits on top of the backdrop (higher z-index) so Cypress's
      // visibility check refuses the click; force it to fire on the backdrop
      // itself — the goal here is to verify the click handler closes the
      // palette, not real-user reachability.
      cy.get('[data-command-target="backdrop"]').click({ force: true })
      cy.get('[data-command-target="panel"]').should('have.class', 'hidden')
    })
  })

  context('searching and filtering', () => {
    beforeEach(() => {
      cy.get('body').type('{meta+k}')
    })

    it('shows recent items by default and hides them once a query is typed', () => {
      // Recents (mode=recent) are visible while the query is empty
      cy.contains('[data-command-target="group"]', 'Recents').should('be.visible')

      cy.get('[data-command-target="input"]').type('policy')
      cy.contains('[data-command-target="group"]', 'Recents').should('not.be.visible')
    })

    it('filters searchable rows to those that match the query', () => {
      cy.get('[data-command-target="input"]').type('Anti-Money')

      // Match
      cy.contains('.cmd-row', 'Anti-Money Laundering Policy v3.2')
        .should('not.have.class', 'hidden')

      // Non-match in the same group
      cy.contains('.cmd-row', 'Code of Ethics and Conduct')
        .should('have.class', 'hidden')
    })

    it('always shows action-mode rows regardless of query', () => {
      cy.get('[data-command-target="input"]').type('xyzzy-no-match')

      cy.contains('.cmd-row', 'New document request')
        .should('not.have.class', 'hidden')
      cy.contains('[data-command-target="group"]', 'Actions').should('be.visible')
    })
  })

  context('keyboard navigation', () => {
    beforeEach(() => {
      cy.get('body').type('{meta+k}')
      cy.get('[data-command-target="input"]').type('Policy')
    })

    it('moves the active row with ArrowDown/ArrowUp', () => {
      // First visible match starts active
      cy.get('.cmd-row.is-active').should('have.length', 1)

      cy.get('[data-command-target="input"]').type('{downarrow}')
      cy.get('.cmd-row.is-active')
        .should('have.length', 1)
        .invoke('text')
        .should('not.be.empty')

      // ArrowUp wraps back to the first visible row
      cy.get('[data-command-target="input"]').type('{uparrow}')
      cy.get('.cmd-row.is-active').should('have.length', 1)
    })

    it('activates the highlighted row on Enter (Turbo navigation)', () => {
      // Stub Turbo so we observe the navigation without actually leaving the page
      cy.window().then(win => {
        win.Turbo = { visit: cy.stub().as('turboVisit') }
      })

      cy.get('[data-command-target="input"]').type('{enter}')
      cy.get('@turboVisit').should('have.been.calledWith', '/lookbook')
    })
  })
})
