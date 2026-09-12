// #1041 — Timeago had no E2E spec. The element is rendered twice: Rails writes
// a relative time into the <time> so the page is never blank without
// JavaScript, and the controller overwrites it with date-fns output on connect.
// What is worth freezing is the part only the browser does — the refresh timer,
// the locale bundle, and what happens when the date does not parse.
describe('Timeago', () => {
  const time = () => cy.get('.timeago-component')

  // Renders a fresh element into the page instead of a preview: the controller
  // reads its datetime once, on connect, so a value that has to be wrong from
  // the start cannot be produced by editing the one already on screen.
  const mount = (win, dataset) => {
    const element = win.document.createElement('time')
    element.className = 'timeago-component probe'
    Object.assign(element.dataset, { controller: 'timeago', ...dataset })
    win.document.body.appendChild(element)
  }

  it('takes over the server-rendered text on connect', () => {
    cy.visit('/bali/timeago/default?add_suffix=true')

    time().should('have.attr', 'datetime')
    time().should('contain.text', 'half a minute')
  })

  it('keeps counting while the page stays open', () => {
    // Frozen at the real current time: the datetime in the page was written by
    // the server seconds ago, and an arbitrary date would put it years away.
    cy.clock(Date.now(), ['setInterval', 'clearInterval', 'Date'])
    cy.visit('/bali/timeago/default?refresh_interval=1000&add_suffix=true')

    time().should('contain.text', 'half a minute ago')

    cy.tick(120000)

    time().should('contain.text', 'minutes ago')
  })

  it('stops counting when no interval was asked for', () => {
    cy.clock(Date.now(), ['setInterval', 'clearInterval', 'Date'])
    cy.visit('/bali/timeago/default?add_suffix=true')

    time().should('contain.text', 'half a minute ago')

    cy.tick(120000)

    // Nothing to fire: the text is whatever connect() left there.
    time().should('contain.text', 'half a minute ago')
  })

  it('formats in the locale it was given', () => {
    cy.visit('/bali/timeago/default')

    cy.window().then((win) => {
      const fiveMinutesAgo = new Date(win.Date.now() - 5 * 60 * 1000).toISOString()
      mount(win, { timeagoDatetimeValue: fiveMinutesAgo, timeagoLocaleValue: 'es' })
    })

    cy.get('.probe').should('have.text', '5 minutos')
  })

  it('echoes an unparseable value instead of printing NaN', () => {
    cy.visit('/bali/timeago/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'error').as('consoleError')
      }
    })

    cy.window().then((win) => {
      mount(win, { timeagoDatetimeValue: 'not a date' })
    })

    // Text, not HTML: the raw value can be host or user data.
    cy.get('.probe').should('have.text', 'not a date')
    cy.get('@consoleError').should('have.been.calledWithMatch', /\[timeago\]/)
  })

  it('renders a span with no controller when there is no datetime', () => {
    cy.visit('/bali/timeago/blank')

    // A <time> is only valid with a machine-readable datetime, and there is
    // none — this used to raise instead.
    cy.get('span.timeago-component').should('have.text', '—')
    cy.get('span.timeago-component').should('not.have.attr', 'data-controller')
    cy.get('time.timeago-component').should('not.exist')
  })
})
