describe('CommandController', () => {
  beforeEach(() => {
    cy.visit('/bali/command/default')
    cy.get('[data-controller="command"]', { timeout: 5000 }).should('exist')
  })

  context('opening and closing', () => {
    it('opens via the default trigger and focuses the input', () => {
      cy.get('.bali-command-trigger').click()

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

    it('shows navigation rows on open and narrows them as the query is typed', () => {
      // Browsable the moment the palette opens — what :searchable cannot do
      cy.contains('.cmd-row', 'Policies').should('not.have.class', 'hidden')
      cy.contains('.cmd-row', 'Committees').should('not.have.class', 'hidden')

      cy.get('[data-command-target="input"]').type('Committees')

      // ...and filtered once there is a query — what :action cannot do
      cy.contains('.cmd-row', 'Committees').should('not.have.class', 'hidden')
      cy.contains('.cmd-row', 'Policies').should('have.class', 'hidden')
    })

    it('counts a matching navigation row as a result, so no empty state shows', () => {
      cy.get('[data-command-target="input"]').type('Committees')

      cy.get('[data-command-target="noResults"]').should('have.class', 'hidden')
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

  // The counter changes on every keystroke, so the controller writes it, with the
  // plural forms component.html.erb hands over in the `results` value
  // (command_test.rb checks that half).
  context('the result counter in the footer', () => {
    const count = () => cy.get('[data-command-target="count"]')
    const openPalette = () => {
      cy.get('.bali-command-trigger').click()
      cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')
    }

    it('counts in the page language', () => {
      cy.visit('/bali/command/default?locale=es')
      openPalette()
      count().should('have.text', '9 resultados')

      cy.get('[data-command-target="input"]').type('Policy')
      count().should('have.text', '2 resultados')
    })

    // The action rows stay on screen under every query, so counting them read
    // "3 results" beneath "No results".
    const noMatchCounts = [
      ['default', 'es', '0 resultados'],
      ['default', 'en', '0 results'],
      ['compact', 'es', '0 resultados'],
      ['compact', 'en', '0 results']
    ]
    noMatchCounts.forEach(([preview, locale, expected]) => {
      it(`agrees with the no-results message when nothing matches (${preview}, ${locale})`, () => {
        cy.visit(`/bali/command/${preview}?locale=${locale}`)
        openPalette()
        cy.get('[data-command-target="input"]').type('xyzzy')

        cy.get('[data-command-target="noResults"]').should('not.have.class', 'hidden')
        cy.get('.cmd-row[data-mode="action"]').should('not.have.class', 'hidden')
        count().should('have.text', expected)
      })
    })

    it('uses the singular form for a single result', () => {
      cy.visit('/bali/command/compact?locale=es')
      openPalette()

      count().should('have.text', '1 resultado')
    })

    // 320px is the width WCAG 1.4.10 asks content to reflow at. Kept on one line
    // there, "9 resultados" runs 42px past the panel, whose overflow-hidden leaves
    // "9 res". Not 360px: there it overflows by about 2px, which a font can erase.
    it('keeps the whole count inside the panel on a phone', () => {
      cy.viewport(320, 760)
      cy.visit('/bali/command/default?locale=es')
      openPalette()

      count().should('have.text', '9 resultados').then($count => {
        const box = $count[0].getBoundingClientRect()
        const panel = $count[0].closest('.cmd-panel').getBoundingClientRect()
        expect(box.right, 'right edge of the count').to.be.at.most(panel.right)
      })
    })

    it('ends the count at the right edge of the footer, on desktop and on a phone', () => {
      [1280, 320].forEach(width => {
        cy.viewport(width, 760)
        cy.visit('/bali/command/default?locale=es')
        openPalette()

        count().should('have.text', '9 resultados').then($count => {
          const footer = $count[0].parentElement
          const edge = footer.getBoundingClientRect().right - parseFloat(getComputedStyle(footer).paddingRight)
          expect($count[0].getBoundingClientRect().right, `right edge of the count at ${width}px`)
            .to.be.closeTo(edge, 1)
        })
      })
    })

    // Hosts pin the gem and the npm package separately, so this controller can
    // meet a palette rendered by a gem that sends no forms.
    it('falls back to English when the markup carries no forms', () => {
      cy.visit('/bali/command/compact?locale=es')
      cy.get('[data-controller="command"]').invoke('removeAttr', 'data-command-results-value')
      openPalette()

      count().should('have.text', '1 result')
    })
  })

  // The trigger's hint is server-rendered, so the HTML says ⌘K to everyone.
  // Only the browser knows which keyboard is in front of the user, so the
  // controller is what corrects it — a Windows user was being pointed at a key
  // their keyboard does not have. Both platforms are stubbed rather than
  // trusting the machine running Cypress, which is a Mac locally and Linux in
  // CI.
  context('the shortcut hint on the trigger', () => {
    const visitAs = (platform, uaPlatform) =>
      cy.visit('/bali/command/default', {
        onBeforeLoad (win) {
          Object.defineProperty(win.navigator, 'platform', {
            value: platform, configurable: true
          })
          Object.defineProperty(win.navigator, 'userAgentData', {
            value: uaPlatform ? { platform: uaPlatform } : undefined,
            configurable: true
          })
        }
      })

    const hint = () =>
      cy.get('.bali-command-trigger kbd[data-command-target="shortcut"]')

    it('reads ⌘K on a Mac', () => {
      visitAs('MacIntel', 'macOS')

      hint().should('have.text', '⌘K')
    })

    it('reads Ctrl K on Windows', () => {
      visitAs('Win32', 'Windows')

      hint().should('have.text', 'Ctrl K')
    })

    it('falls back to navigator.platform when userAgentData is missing', () => {
      visitAs('Linux x86_64', null)

      hint().should('have.text', 'Ctrl K')
    })
  })
})
