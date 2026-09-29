describe('DrawerController', () => {
  // `submit` is inherited from ModalController, so this covers both overlays.
  //
  // The waiting state used to be `classList.add('loading')` on the button. In
  // daisyUI 5 `.loading` is not a modifier that adds a spinner — it IS the
  // spinner: `aspect-ratio: 1`, a six-unit width, and `background-color:
  // currentColor` masked by the spinner SVG. On the <button> it collapsed the box
  // (measured 66x40 to 34x40) and painted the button itself as the spinner, with
  // the label still inside showing through the holes in the mask (#839).
  context('submit button waiting state', () => {
    const SUBMIT = '[data-action="drawer#submit"]'

    beforeEach(() => {
      cy.visit('/bali/drawer/turbo_stream_form')
      cy.get('.drawer-open').should('exist')
    })

    it('keeps the button box and puts the spinner inside it', () => {
      // Held pending on purpose: the waiting state is only observable while the
      // request is in flight.
      cy.intercept('POST', '/fake/submit*', {
        delay: 8000,
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: '<turbo-stream action="append" target="stream-target"><template><p>ok</p></template></turbo-stream>'
      }).as('submit')

      let width
      cy.get(SUBMIT).then($b => { width = $b[0].getBoundingClientRect().width })
      cy.get(SUBMIT).click()

      cy.get(SUBMIT).should('have.attr', 'disabled')
      cy.get(SUBMIT).should('have.attr', 'aria-busy', 'true')
      cy.get(SUBMIT).should('not.have.class', 'loading')
      cy.get(SUBMIT).should($b => {
        // The box the user was looking at does not move. Without pinning, swapping
        // the label for a 20px spinner resizes the actions row at exactly the
        // moment the user is waiting on it. And the button paints itself, not the
        // spinner: `mask-image` is what `.loading` on the <button> turned on.
        expect($b[0].getBoundingClientRect().width).to.be.closeTo(width, 1)
        expect(getComputedStyle($b[0]).maskImage).to.equal('none')
      })

      // The spinner is a child, and the label is out of sight rather than merely
      // covered by it — reading textContent would pass either way.
      cy.get(`${SUBMIT} .loading.loading-spinner`).should('be.visible')
      cy.get(`${SUBMIT} [data-bali-submit-label]`).should('not.be.visible')
    })

    it('gives the label back when the form does not validate', () => {
      cy.get('#name').invoke('attr', 'required', 'required')

      let width
      cy.get(SUBMIT).then($b => { width = $b[0].getBoundingClientRect().width })
      cy.get(SUBMIT).click()

      // `reportValidity()` fails before the fetch, so this is the one path that
      // comes back to a button that is still on screen.
      cy.get(SUBMIT).should('not.have.attr', 'disabled')
      cy.get(SUBMIT).should('not.have.attr', 'aria-busy')
      cy.get(SUBMIT).should('contain.text', 'Save')
      cy.get(`${SUBMIT} .loading`).should('not.exist')
      cy.get(SUBMIT).should($b => {
        expect($b[0].getBoundingClientRect().width).to.be.closeTo(width, 1)
        expect($b[0].style.minWidth).to.equal('')
      })
    })
  })

  // `submit` calls `event.preventDefault()` before validating, so the browser is not going
  // to report anything on its own: if the controller does not ask for it, nobody does. Until
  // #894 it asked by walking `input` by hand, so a required `<textarea>` or a `<select>`
  // blocked the submit silently — no request, no message, no bubble and no focus anywhere.
  // The native bubble cannot be read from the DOM; focus can, and it is where
  // `reportValidity()` leaves the first invalid control.
  context('required fields that are not <input>', () => {
    const SUBMIT = '[data-action="drawer#submit"]'
    const focusedId = () => cy.window().then(win => win.document.activeElement.id)

    beforeEach(() => {
      cy.visit('/bali/drawer/required_fields')
      cy.get('.drawer-open').should('exist')
      cy.intercept('POST', '/fake/submit*', { body: 'ok' }).as('submit')
    })

    it('stops at the first invalid control and sends nothing', () => {
      cy.get(SUBMIT).click()

      focusedId().should('equal', 'required-name')
      cy.get('@submit.all').should('have.length', 0)
    })

    it('reports a required <textarea>', () => {
      cy.get('#required-name').type('Something')
      cy.get(SUBMIT).click()

      focusedId().should('equal', 'required-description')
      cy.get('@submit.all').should('have.length', 0)
    })

    it('reports a required <select>', () => {
      cy.get('#required-name').type('Something')
      cy.get('#required-description').type('A description')
      cy.get(SUBMIT).click()

      focusedId().should('equal', 'required-urgency')
      cy.get('@submit.all').should('have.length', 0)
    })

    it('lets the submit through once every control is filled', () => {
      cy.get('#required-name').type('Something')
      cy.get('#required-description').type('A description')
      cy.get('#required-urgency').select('high')
      cy.get(SUBMIT).click()

      cy.wait('@submit')
    })
  })

  context('turbo_stream form submit', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/turbo_stream_form')
    })

    it('applies the turbo stream response and closes the drawer', () => {
      cy.intercept('POST', '/fake/submit*', {
        headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
        body: `
          <turbo-stream action="append" target="stream-target">
            <template><p id="stream-result">It worked</p></template>
          </turbo-stream>
        `
      }).as('submit')

      cy.get('.drawer-open').should('exist')
      cy.get('[data-action="drawer#submit"]').click()
      cy.wait('@submit')

      // The stream is applied to the page...
      cy.get('#stream-result').should('have.text', 'It worked')
      // ...not injected as inert markup inside the drawer
      cy.get('turbo-stream').should('not.exist')
      // ...and the drawer closes
      cy.get('.drawer-open').should('not.exist')
    })

    it('keeps HTML error responses inside the drawer (unchanged behavior)', () => {
      cy.intercept('POST', '/fake/submit*', {
        statusCode: 422,
        headers: { 'Content-Type': 'text/html' },
        body: '<form action="/fake/submit" data-turbo="true"><p id="form-error">Name is required</p></form>'
      }).as('submit')

      cy.get('[data-action="drawer#submit"]').click()
      cy.wait('@submit')

      // Error form re-renders inside the drawer, which stays open
      cy.get('.drawer-open').should('exist')
      cy.get('.drawer-open #form-error').should('have.text', 'Name is required')
    })

    // The error branch used to route through `openModal`, which resets the dirty
    // flag. So a failed submit disarmed the confirm-on-close at the exact moment
    // the form held the most unsaved input.
    it('still guards the unsaved form after a failed submit', () => {
      cy.intercept('POST', '/fake/submit*', {
        statusCode: 422,
        headers: { 'Content-Type': 'text/html' },
        body: '<form action="/fake/submit" data-turbo="true"><p id="form-error">Name is required</p></form>'
      }).as('submit')

      cy.get('#name').type('Something worth keeping')
      cy.get('[data-action="drawer#submit"]').click()
      cy.wait('@submit')
      cy.get('#form-error').should('exist')

      // The re-rendered error body has nothing focusable, so focus falls back to
      // the panel — which is what keeps Escape reaching the drawer at all.
      cy.focused().type('{esc}', { force: true })

      cy.get('dialog[data-bali-confirm]').should('be.visible')
      cy.get('.drawer-open').should('exist')
    })
  })

  context('confirm on close (unsaved changes)', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/dirty_form')
      cy.get('.drawer-open').should('exist')
    })

    it('prompts before discarding an edited form on Escape; cancel keeps the values', () => {
      cy.get('#form_record_text').type('Hello')

      // Escape originates inside the drawer so it reaches the drawer#close action
      cy.get('#form_record_text').type('{esc}')

      // Confirmation dialog appears and the drawer stays open
      cy.get('dialog[data-bali-confirm]').should('be.visible')
      cy.get('.drawer-open').should('exist')

      // Cancelling keeps the drawer open with the typed value intact
      cy.get('#bali-confirm-cancel-btn').click()
      cy.get('.drawer-open').should('exist')
      cy.get('#form_record_text').should('have.value', 'Hello')

      // Escape again + accept closes the drawer
      cy.get('#form_record_text').type('{esc}')
      cy.get('#bali-confirm-accept-btn').click()
      cy.get('dialog[data-bali-confirm]').should('not.be.visible')
      cy.get('.drawer-open').should('not.exist')
    })

    it('closes without prompting when the form is untouched', () => {
      cy.get('#form_record_text').type('{esc}')

      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('not.exist')
    })
  })

  context('flatpickr calendar inside the drawer', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/dirty_form')
      cy.get('.drawer-open').should('exist')
    })

    it('first Escape closes the calendar, second Escape closes the (clean) drawer', () => {
      // flatpickr renders its calendar on document.body, outside the drawer DOM.
      // Its alt input is readonly, so Escape needs `force` to dispatch the keydown.
      cy.get('.flatpickr input').filter(':visible').first().click()
      cy.get('.flatpickr-calendar.open').should('exist')

      // First Escape: flatpickr consumes it and closes the calendar; drawer stays
      cy.get('.flatpickr input').filter(':visible').first().type('{esc}', { force: true })
      cy.get('.flatpickr-calendar.open').should('not.exist')
      cy.get('.drawer-open').should('exist')

      // Second Escape: form is still clean, so the drawer closes without a prompt
      cy.get('.flatpickr input').filter(':visible').first().type('{esc}', { force: true })
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('not.exist')
    })

    // #1013 — the calendar enters the top layer INSIDE the dialog (enterTopLayer),
    // as a sibling of the wrapper: to the overlay detection its clicks were "a
    // click outside" and, with a dirty form, paging the month asked whether you
    // wanted to close the drawer. The days never surfaced it, only because
    // selecting closes the calendar before the click finishes its path.
    it('paging the calendar month does not ask to close the dirty drawer', () => {
      cy.get('#form_record_text').type('Hello')

      cy.get('.flatpickr input').filter(':visible').first().click()
      cy.get('.flatpickr-calendar.open').should('exist')

      cy.get('.flatpickr-calendar.open .flatpickr-next-month').click()
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.flatpickr-calendar.open').should('exist')
      cy.get('.drawer-open').should('exist')

      cy.get('.flatpickr-calendar.open .flatpickr-prev-month').click()
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('exist')
    })

    // #1013, the other half: SlimSelect's .ss-content enters the dialog through the
    // same enterTopLayer (it ends up [popover]) and its clicks — the search field,
    // picking an option that re-renders the content — counted as a click outside
    // just like the calendar.
    it('searching and picking in the slim select does not ask to close the dirty drawer', () => {
      cy.get('#form_record_text').type('Hello')

      cy.get('.drawer-open .ss-main').first().click()
      cy.get('.ss-content .ss-search input').should('be.visible').click().type('Com')
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('exist')

      // Picking re-renders the content: the target can reach the click already
      // detached, and composedPath still counts it as inside.
      cy.get('.ss-content .ss-list .ss-option').contains('Comedy').click()
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('exist')
    })

    // #1013, third half: dismissing the system file picker fires a `cancel` event
    // that DOES bubble from the input (unlike the dialog's own cancel, which does
    // not), and the drawer's cancel listener took it as a platform close request.
    // Cypress cannot touch the native picker, so the test dispatches the same event
    // the browser dispatches.
    it('cancelling the file picker does not ask to close the dirty drawer', () => {
      cy.get('#form_record_text').type('Hello')

      cy.get('.drawer-open input[type="file"]').then(([input]) => {
        input.dispatchEvent(new Event('cancel', { bubbles: true }))
      })
      cy.get('dialog[data-bali-confirm]').should('not.exist')
      cy.get('.drawer-open').should('exist')
    })

    // The control case for the fix: the real close gesture must not get run over —
    // the actual overlay still asks about a dirty form.
    it('clicking the real overlay still asks for confirmation on a dirty form', () => {
      cy.get('#form_record_text').type('Hello')

      cy.get('[data-drawer-target="background"]').click({ force: true })
      cy.get('dialog[data-bali-confirm]').should('be.visible')
      cy.get('.drawer-open').should('exist')
    })
  })
})
