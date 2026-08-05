// A `<dialog>` opened with `showModal()` paints in the top layer — above the whole
// document and above every z-index — and makes every node outside its own subtree
// inert. Widgets that portal their popup to `<body>` therefore stop being usable
// inside one: the popup is covered AND it takes no pointer events.
//
// These specs stand in for a host that owns such a dialog: they build a modal
// dialog around a real Bali form and then drive the widgets with real clicks.
// `cy.click()` fails on an element another element covers, which is exactly the
// failure being guarded against — no `{ force: true }` anywhere below, on purpose.
// Bali's own Modal and Drawer are dialogs too now; `overlays-in-the-top-layer.cy.js`
// is where they are covered, so this file stays about the hand-built case.

const DIALOG_ID = 'host-dialog'

// With `altInput` on — the default — flatpickr turns the field Rails rendered into
// `type="hidden"` and inserts the one the user actually types into right after it.
const DATE_INPUT = '#form_record_date + input'

const isInTopLayer = $el => expect($el[0].matches(':popover-open')).to.equal(true)
const isNotInTopLayer = $el => expect($el[0].matches(':popover-open')).to.equal(false)

const wrapFormInModalDialog = () =>
  cy.document().then(doc => {
    const dialog = doc.createElement('dialog')
    dialog.id = DIALOG_ID
    dialog.className = 'modal'
    dialog.innerHTML =
      '<div class="modal-box relative bg-base-100 rounded-box p-4 sm:p-6 shadow-xl ' +
      'w-11/12 max-h-[calc(100vh-5em)] overflow-y-auto" id="host-dialog-box"></div>'

    doc.body.appendChild(dialog)
    // Open first, then move the form in: that is the order the package uses, and
    // it is what lets a controller connecting inside the panel see the dialog.
    dialog.showModal()
    doc.getElementById('host-dialog-box').appendChild(doc.querySelector('form'))
  })

describe('Popups opened from inside a top-layer overlay', () => {
  describe('flatpickr calendar', () => {
    beforeEach(() => {
      cy.visit('/bali/drawer/dirty_form')
      cy.get(DATE_INPUT).should('be.visible')
      wrapFormInModalDialog()
      cy.get(`#${DIALOG_ID} ${DATE_INPUT}`).should('be.visible')
    })

    it('joins the top layer from inside the dialog', () => {
      cy.get(DATE_INPUT).click()

      cy.get('.flatpickr-calendar.open')
        .should('have.attr', 'popover', 'manual')
        .and(isInTopLayer)
        .parent()
        .should('have.id', DIALOG_ID)
    })

    it('lets a day be picked with a real click', () => {
      cy.get(DATE_INPUT).click()

      cy.get('.flatpickr-calendar.open')
        .find('.flatpickr-day:not(.prevMonthDay):not(.nextMonthDay)')
        .contains('15')
        .click()

      cy.get('#form_record_date').invoke('val').should('match', /^\d{4}-\d{2}-15$/)
      cy.get(DATE_INPUT).invoke('val').should('match', /^15\//)
    })

    it('leaves the top layer when the calendar closes', () => {
      cy.get(DATE_INPUT).click()
      cy.get('.flatpickr-calendar.open').should(isInTopLayer)

      // Escape on the field is what closes it; flatpickr drives the exit.
      cy.get(DATE_INPUT).type('{esc}')
      cy.get('.flatpickr-calendar').should('not.have.class', 'open')
      cy.get('.flatpickr-calendar').should(isNotInTopLayer)
    })
  })

  describe('SlimSelect list', () => {
    beforeEach(() => {
      cy.visit('/bali/form/slim_select/default')
      cy.get('.ss-main').should('exist')
      wrapFormInModalDialog()
      // The controller reconnects inside the open dialog and rebuilds the widget.
      cy.get(`#${DIALOG_ID} > .ss-content`).should('exist')
    })

    it('joins the top layer from inside the dialog', () => {
      cy.get('.ss-content').should('have.attr', 'popover', 'manual').and(isInTopLayer)
    })

    it('lets an option be picked with a real click', () => {
      cy.get('.ss-main').click()
      cy.get('.ss-content .ss-option').contains('Option 3').click()

      cy.get('select').should('have.value', '3')
      cy.get('.ss-main').should('contain', 'Option 3')
    })
  })

  // `bali/form/date/default` and not the drawer preview this used to use: since
  // Drawer became a `<dialog>`, a field inside one is never the no-overlay case.
  describe('outside a top-layer overlay', () => {
    it('leaves the calendar exactly where flatpickr puts it', () => {
      cy.visit('/bali/form/date/default')
      cy.get(DATE_INPUT).should('be.visible').click()

      cy.get('.flatpickr-calendar.open').should('not.have.attr', 'popover')
      cy.get('.flatpickr-calendar.open').parent().should('match', 'body')

      cy.get('.flatpickr-calendar.open')
        .find('.flatpickr-day:not(.prevMonthDay):not(.nextMonthDay)')
        .contains('15')
        .click()

      cy.get('#form_record_date').invoke('val').should('match', /^\d{4}-\d{2}-15$/)
    })

    it('leaves the SlimSelect list under body', () => {
      cy.visit('/bali/form/slim_select/default')

      cy.get('body > .ss-content').should('exist').and('not.have.attr', 'popover')
    })
  })
})
