// #1415: on a DataTable, every Back added another date field beside the filter's — a copy of the
// altInput that opens nothing. Two defects met: the toolbar re-appended every control on
// `turbo:before-cache`, reconnecting the filter's datepicker, and that reconnect finished on the
// page Turbo was leaving, so the snapshot carried a live altInput no `disconnect()` destroyed.
describe('A date filter and the Back button', () => {
  const appOrigin = new URL(Cypress.config('baseUrl')).origin
  // A custom range puts the picker on screen instead of behind the period select. Spanish
  // because the race needs its locale import: with `en` the reconnect lands before the swap.
  const studios = `${appOrigin}/admin/studios?locale=es&q%5Bcreated_at%5D=2026-01-01+to+2026-03-31`
  const picker = '[data-controller~="toolbar-overflow"] [data-controller~="datepicker"]'

  // The input a live flatpickr turned hidden. A snapshot cloned mid-mount carries it hidden too,
  // but not the `_flatpickr` expando, so only this says the restored page has connected.
  const mounted = () =>
    cy.get(`${picker} input[type="hidden"]`).should(($input) => {
      expect($input[0]._flatpickr, 'flatpickr mounted').to.be.an('object')
    })

  it('comes back with one date field that opens the calendar', () => {
    cy.viewport(1440, 900)
    cy.visit(studios)
    mounted()

    cy.window().then((win) => win.Turbo.visit('/admin/settings'))
    cy.location('pathname').should('eq', '/admin/settings')
    cy.go('back')
    cy.location('pathname').should('eq', '/admin/studios')
    mounted()

    cy.get(picker).find('input:not([type="hidden"])').should('have.length', 1).click()
    cy.get('.flatpickr-calendar.open').should('be.visible')

    // The snapshot keeps whatever a connect wrote on the element, so a write there piles up.
    cy.request(studios).its('body').then((html) => {
      const served = new DOMParser().parseFromString(html, 'text/html').querySelector(picker)
      cy.get(picker).should('have.attr', 'data-datepicker-alt-input-class-value',
        served.dataset.datepickerAltInputClassValue)
    })
  })

  // Expanding the row for the snapshot brings back what sits in the ⋯ — at 1440px group by,
  // columns, saved views and the persistence marker — but the filters never left their place,
  // and a move is a reconnect of everything inside them.
  it('leaves the date filter in place when Turbo caches the page', () => {
    cy.viewport(1440, 900)
    cy.visit(studios)
    mounted()
    cy.get('[data-toolbar-overflow-target="menu"]').children().should('have.length.at.least', 1)

    cy.get(picker).closest('[data-toolbar-overflow-target="item"]').then(($filters) => {
      const filters = $filters[0]
      const win = filters.ownerDocument.defaultView
      win.filterMoves = 0
      new win.MutationObserver((records) => {
        win.filterMoves += records.filter(record => [...record.addedNodes].includes(filters)).length
      }).observe(filters.parentNode, { childList: true })

      win.Turbo.visit('/admin/settings')
    })
    cy.location('pathname').should('eq', '/admin/settings')
    cy.window().its('filterMoves').should('eq', 0)
  })

  // The datepicker on its own, with no toolbar: whatever moves it, a connect that resolves
  // after the field left the page must not mount on it.
  it('mounts nothing on a field that left the page while flatpickr was loading', () => {
    cy.visit('/bali/form/date/default')
    cy.get('[data-controller~="datepicker"] input[type="hidden"]')

    let field
    cy.window().then((win) => {
      field = win.document.querySelector('[data-controller~="datepicker"]')
      const controller = win.Stimulus.getControllerForElementAndIdentifier(field, 'datepicker')
      const connect = controller.connect.bind(controller)

      return new Cypress.Promise((resolve) => {
        controller.connect = () => {
          const connecting = connect()
          field.remove()
          connecting.then(resolve)
          return connecting
        }
        // A move: Stimulus disconnects the controller and connects it again.
        field.parentNode.insertBefore(field, field.nextSibling)
      })
    }).then(() => {
      // Mounted, flatpickr hides the input and adds its altInput beside it.
      expect(field.querySelectorAll('input'), 'inputs in the field').to.have.length(1)
      expect(field.querySelector('input').type).to.equal('text')
    })
  })
})
