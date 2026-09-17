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

  // The month view has always been able to link one event; the year view puts the
  // same partial inside a tippy popper, and a popper is where that stops being
  // obvious. `interactive: true` in the hovercard controller is what lets the
  // pointer leave the day square and land on the link — without it the card
  // closes on the way there and the link is unreachable by mouse.
  it('lets an event inside the hover card be clicked through to its own url', () => {
    cy.viewport(1440, 1200)
    cy.visit(year)

    cy.get('.hover-card-component').eq(1).find('[data-hovercard-target="trigger"]')
      .trigger('mouseenter')

    cy.get('.tippy-box a.tag-component').should('have.length', 2).first().then($a => {
      const a = $a[0]
      const r = a.getBoundingClientRect()
      const hit = a.ownerDocument.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2)
      // The pointer genuinely reaches the link: nothing is painted over it.
      expect(a.contains(hit) || hit === a, 'link is the topmost element').to.equal(true)
    })

    cy.get('.tippy-box a.tag-component').first().click()
    cy.location('pathname').should('include', '/bali/calendar/default')
    cy.location('search').should('include', 'start_date=')
  })

  // #655's rule — a `.tag-component` is single-line — is right for a table cell
  // and wrong inside a hover card tippy caps at 350px. Before the
  // `whitespace-normal h-auto` opt-out in the preview partial, a name this long
  // measured 367px and drew its own background past the card's right edge.
  it('wraps a long event name instead of spilling it outside the card', () => {
    cy.viewport(1440, 1200)
    cy.visit(year)

    cy.get('.hover-card-component').eq(1).find('[data-hovercard-target="trigger"]')
      .trigger('mouseenter')

    cy.get('.tippy-box').should('be.visible').then($box => {
      const box = $box[0]
      const boxRect = box.getBoundingClientRect()
      const long = [...box.querySelectorAll('a.tag-component')]
        .find(a => a.textContent.includes('deliberately long name'))

      expect(long, 'the long-named event is in the card').to.not.equal(undefined)
      const r = long.getBoundingClientRect()

      expect(r.right, 'stays inside the card').to.be.at.most(boxRect.right + 1)
      expect(long.scrollHeight, 'no line is clipped').to.be.at.most(long.clientHeight + 1)
      // Two line boxes at this width: it wrapped rather than being cut off.
      expect(r.height, 'grew to fit the wrapped text').to.be.greaterThan(28)
    })
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
