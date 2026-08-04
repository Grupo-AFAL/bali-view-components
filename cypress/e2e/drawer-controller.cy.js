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

  // `submit` hace `event.preventDefault()` antes de validar, así que el navegador no va a
  // reportar nada por su cuenta: si el controlador no lo pide, no lo pide nadie. Hasta #894
  // lo pedía recorriendo `input` a mano, así que un `<textarea>` o un `<select>` requerido
  // bloqueaba el envío en silencio — sin petición, sin mensaje, sin globo y sin foco en
  // ninguna parte. El globo nativo no se puede leer desde el DOM; el foco sí, y es donde
  // `reportValidity()` deja al primer control inválido.
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
  })
})
