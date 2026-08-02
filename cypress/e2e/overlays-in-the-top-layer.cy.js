// Modal, Drawer and Command open with `showModal()`, which paints them in the top
// layer and makes everything outside them inert. Two things follow, and both are
// only observable in a browser:
//
//   * every popup a field portals to <body> has to be brought back in, and
//   * every overlay the stacking scale ranks ABOVE them has to join the top layer
//     too, because no z-index reaches over it.
//
// `top-layer-popups.cy.js` covers the first for a hand-built dialog. This covers
// the real components, and the second half.
describe('overlays in the top layer', () => {
  const appOrigin = new URL(Cypress.config('baseUrl')).origin

  const isTopLayerDialog = (selector) =>
    cy.get(selector).should($el => {
      expect($el[0].tagName).to.equal('DIALOG')
      expect($el[0].open, 'open').to.equal(true)
      expect($el[0].matches(':modal'), ':modal').to.equal(true)
    })

  context('Drawer', () => {
    beforeEach(() => cy.visit('/bali/drawer/dirty_form'))

    // A panel rendered `active:` arrives with the open class and no script in the
    // loop, so the controller has to promote it on connect or a server-opened
    // drawer would be the one overlay that is not in the top layer.
    it('is a modal <dialog> when the server rendered it open', () => {
      isTopLayerDialog('.drawer-component')
    })

    it('leaves the top layer on close and keeps the panel rendered for the slide-out', () => {
      cy.get('.drawer-header button').click()

      cy.get('.drawer-component').should($el => {
        expect($el[0].open, 'open').to.equal(false)
        expect($el[0].matches(':modal'), ':modal').to.equal(false)
        // The UA hides a closed dialog; the package puts it back, or the panel
        // would blink out instead of sliding away.
        expect(getComputedStyle($el[0]).display).to.equal('block')
      })
    })

    // flatpickr's calendar is portaled to <body>, so inside a modal dialog it is
    // both painted under the panel and made inert. This is the case that blocked
    // the whole conversion.
    it('lets a real click reach a day in the calendar', () => {
      cy.get('.flatpickr input').filter(':visible').first().click()
      cy.get('.flatpickr-calendar.open').should('exist')

      cy.get('.flatpickr-calendar').should($cal => {
        expect($cal[0].closest('dialog'), 'reparented into the dialog').to.not.equal(null)
        expect($cal[0].matches(':popover-open'), ':popover-open').to.equal(true)
      })

      // No `{ force: true }` anywhere: cy.click() fails when something covers the
      // target, which is exactly the failure being guarded against.
      cy.get('.flatpickr-day:not(.prevMonthDay):not(.nextMonthDay)').contains('15').click()
      cy.get('#form_record_date').invoke('val').should('match', /^\d{4}-\d{2}-15$/)
    })
  })

  context('Modal', () => {
    it('is a modal <dialog> when the server rendered it open', () => {
      cy.visit('/bali/modal/form_modal')
      isTopLayerDialog('.modal-component')
    })

    it('is a modal <dialog> when a trigger opened it', () => {
      cy.visit('/bali/modal/default?active=false')
      cy.get('[data-modal-target="template"]').should('not.have.class', 'modal-open')

      cy.window().then(win => {
        win.document.dispatchEvent(
          new win.CustomEvent('bali:modal:open', {
            detail: { content: '<p id="loaded">hi</p>', options: {} }
          })
        )
      })

      isTopLayerDialog('.modal-component')
    })
  })

  // `--bali-z-command: 500` used to be enough to open the palette over a modal.
  // It is not any more, so the palette became a dialog of its own: the top layer
  // stacks by the order things entered it, and the palette enters last.
  context('Command palette over an open overlay', () => {
    it('opens above a drawer that is already in the top layer', () => {
      cy.visit(`${appOrigin}/z-stack`)

      isTopLayerDialog('[data-command-target="surface"]')

      cy.get('[data-command-target="input"]').should($input => {
        const rect = $input[0].getBoundingClientRect()
        const hit = $input[0].ownerDocument.elementFromPoint(
          rect.left + rect.width / 2,
          rect.top + rect.height / 2
        )
        expect($input[0].contains(hit) || hit === $input[0], 'the input is the top-most thing at its own centre').to.equal(true)
      })
    })
  })

  // The scale promises a toast above the dialog it is reporting on, and a failed
  // submit is exactly the flow that leaves the panel open under it.
  context('Toast stack over an open overlay', () => {
    it('moves into the overlay and back out when it closes', () => {
      cy.visit(`${appOrigin}/z-stack`)

      // The palette auto-opens on this page and would legitimately cover the
      // toast, being the last thing into the top layer.
      cy.window().then(win => win.dispatchEvent(new win.Event('bali:command:close')))

      cy.get('.toast-container-component').should($stack => {
        const host = $stack[0].parentElement
        expect(host.tagName, 'parent').to.equal('DIALOG')
        expect(host.matches(':modal'), 'parent is in the top layer').to.equal(true)
        expect($stack[0].matches(':popover-open'), ':popover-open').to.equal(true)
      })

      cy.get('.toast-component').should($toast => {
        const rect = $toast[0].getBoundingClientRect()
        const hit = $toast[0].ownerDocument.elementFromPoint(
          rect.left + rect.width / 2,
          rect.top + rect.height / 2
        )
        expect($toast[0].contains(hit) || hit === $toast[0], 'the toast is not covered').to.equal(true)
      })

      // Closing every overlay hands the stack back rather than taking it down
      // with the panel.
      cy.window().then(win => {
        win.document.querySelectorAll('dialog[open]').forEach(dialog => dialog.close())
      })

      cy.get('.toast-container-component').should($stack => {
        expect($stack[0].closest('dialog'), 'back out of the dialog').to.equal(null)
        expect($stack[0].matches(':popover-open'), ':popover-open').to.equal(false)
      })
    })
  })

  // The embed's credential is a bearer token. A URL is written to the server's
  // access log, offered in the `Referer` of anything the embed loads, and kept in
  // browser history, so it travels by `postMessage` instead — which only a browser
  // can prove actually arrives.
  context('FeedbackWidget token', () => {
    it('reaches the embed by message and never through its URL', () => {
      cy.visit(`${appOrigin}/feedback-widget-demo`)

      cy.get('[data-action="feedback-widget#open"]').click()

      isTopLayerDialog('#feedback-widget')

      cy.get('.feedback-widget-embed')
        .should('have.attr', 'src')
        .and('not.contain', 'token')

      cy.get('.feedback-widget-embed').its('0.contentDocument').should('exist')
      cy.get('.feedback-widget-embed')
        .its('0.contentDocument.body')
        .find('#query-string')
        .should('have.text', '(empty)')
      cy.get('.feedback-widget-embed')
        .its('0.contentDocument.body')
        .find('#received-token')
        .should('have.text', 'demo-token-123')
    })
  })
})
