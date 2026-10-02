import { paintedContrast } from '../support/painted_contrast'
import { tap } from '../support/tap'
import { THEMES } from '../support/themes'

// The hovercard controller mounts its tippy in `connect()`, so a card on every
// cell would cost 365 instances; `hover?` restricts it to days with events.
describe('Calendar year view', () => {
  const year = '/bali/calendar/year'

  it('mounts one hover card per day with events, and none on the empty days', () => {
    cy.viewport(1440, 1200)
    cy.visit(year)

    cy.get('.year-day').should('have.length.greaterThan', 364)

    // 12 months x 3 distinct days carrying the sample events.
    cy.get('.hover-card-component').should('have.length', 36)
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

  // Without `day_url` the cell is a `<time>`, which takes no focus by itself; the
  // card opens on `focusin`, so the tab stop is what makes its events reachable
  // without a mouse.
  it('opens the hover card from the keyboard when the day is not a link', () => {
    cy.viewport(1440, 1200)
    cy.visit(`${year}?with_day_url=false`)

    cy.get('time.year-day[tabindex="0"]').should('have.length', 36)
      .first().should('have.attr', 'aria-label').and('match', /^\d+ \w+ \d{4}$/)

    cy.get('time.year-day[tabindex="0"]').first().focus()
    cy.focused().should('have.class', 'year-day')
    cy.get('.tippy-box').should('be.visible').within(() => {
      cy.get('.badge').should('have.length.greaterThan', 0)
    })
  })

  // The dimmed number of an empty day and the weekday initials are translucent
  // `text-base-content/*` tokens, so what the reader sees is the token COMPOSITED
  // over the ground (#1203). Shipped at `/40` and `/50` they measured 2.36:1 and
  // 3.05:1 on `afal`; AA wants 4.5 for text this size.
  THEMES.forEach((theme) => {
    it(`reads the empty day number and the weekday initials at AA on the ${theme} theme`, () => {
      cy.viewport(1440, 1200)
      cy.visit(year)
      cy.get('.year-day').should('have.length.greaterThan', 364)
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.document().should((doc) => {
        expect(doc.getAnimations(), 'transitions settled').to.have.length(0)

        ;[['empty day number', 'time.year-day:not([tabindex])'], ['weekday initial', '.year-weekday']]
          .forEach(([what, selector]) => {
            expect(paintedContrast(doc.querySelector(selector)), `${theme}: the ${what}`).to.be.at.least(4.5)
          })
      })
    })
  })

  // `interactive: true` in the hovercard controller is what lets the pointer leave
  // the day square and reach the link; without it the card closes on the way.
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

  // `defaultPrevented` is read on `document`, before Turbo's listener on `window`
  // prevents every click it follows.
  it('opens a linked day\'s card on the first tap and follows day_url on the second', () => {
    cy.viewport(390, 844)
    cy.visit(year)
    const day = () => cy.get('.hover-card-component a.year-day').eq(1)
    day().should($a => expect($a.closest('[data-hovercard-target]')[0]._tippy, 'tippy mounted').to.exist)
    cy.document().then(doc => {
      const prevented = []
      doc.addEventListener('click', e => prevented.push(e.defaultPrevented))
      cy.wrap(prevented).as('prevented')
    })

    day().then(tap)
    cy.get('@prevented').should('deep.equal', [true])
    cy.get('.tippy-box').should('be.visible').find('.badge').should('have.length.greaterThan', 0)

    day().then(tap)
    cy.location('pathname').should('eq', '/lookbook/preview/bali/calendar/default')
  })

  // Tippy caps the card at 350px; before the preview partial's `whitespace-normal
  // h-auto` opt-out (#655) a name this long measured 367px and spilled past it.
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
