// The year view's two claims that only a browser can settle: a hover card
// actually opens with the host's own partial inside it, and tippy is mounted
// ONLY on the days that have something to show. The second one is the reason
// `hover?` exists at all — the hovercard controller creates its tippy instance
// in `connect()`, so an unrestricted year view would mount one per day.
describe('Calendar year view', () => {
  const year = '/bali/calendar/year'

  it('mounts one hover card per day with events, and none on the empty days', () => {
    cy.viewport(1440, 1200)
    cy.visit(year)

    cy.get('.year-day').should('have.length.greaterThan', 364)

    // 12 months x 3 distinct days carrying the sample events.
    cy.get('.hover-card-component').should('have.length', 36)

    cy.window().then(win => {
      const cards = win.document.querySelectorAll('.hover-card-component')
      const days = win.document.querySelectorAll('.year-day')
      cy.log(`hover cards: ${cards.length} of ${days.length} days`)
    })
  })

  it('opens the hover card with the host template inside it', () => {
    cy.viewport(1440, 1200)
    cy.visit(year)

    cy.get('.hover-card-component').first().find('[data-hovercard-target="trigger"]')
      .trigger('mouseenter')

    cy.get('.tippy-box').should('be.visible').within(() => {
      cy.get('.badge').should('have.length.greaterThan', 0)
    })
  })

  it('links a day when the host gave it a url and leaves it alone otherwise', () => {
    cy.viewport(1440, 1200)
    cy.visit(year)

    cy.get('a.year-day').should('have.length', 36)
    cy.get('time.year-day').should('have.length.greaterThan', 300)

    cy.visit(`${year}?with_day_url=false`)
    cy.get('a.year-day').should('not.exist')
  })

  it('keeps the seven columns when weekdays_only is set', () => {
    cy.viewport(1440, 1200)
    cy.visit(`${year}?weekdays_only=true`)

    cy.get('.year-weekday').should('have.length', 84)
    cy.get('.year-day').should('have.length.greaterThan', 364)
  })

  it('reflows to a single column of months on a phone', () => {
    cy.viewport(390, 844)
    cy.visit(year)

    cy.get('.year-month').should('have.length', 12)

    cy.get('.year-month').then($months => {
      const first = $months[0].getBoundingClientRect()
      const second = $months[1].getBoundingClientRect()
      expect(second.top).to.be.greaterThan(first.top)
      expect(Math.round(second.left)).to.eq(Math.round(first.left))
    })
  })
})
