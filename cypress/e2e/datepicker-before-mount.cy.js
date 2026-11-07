import { holdChunk } from '../support/chunks'

// flatpickr arrives in a chunk after the page is interactive, so a click can land on the field
// before it mounts. Its `focus` and `click` listeners never saw that click, and its altInput
// turns the clicked field into `type=hidden`, which drops the focus: the calendar stayed shut
// and the keyboard reached nothing until a second click.
describe('Datepicker: a field clicked before flatpickr mounts', () => {
  // esbuild names a chunk after its module's file, and an `index.js` after its folder:
  // flatpickr's `dist/esm/index.js`.
  const holdFlatpickr = () => holdChunk('esm')

  it('opens the calendar and hands the focus to the field flatpickr draws', () => {
    const flatpickr = holdFlatpickr()
    cy.visit('/bali/form/date/default')
    flatpickr.requested()

    cy.get('#form_record_date').click()
    cy.get('#form_record_date').should($f => expect($f[0]._flatpickr, 'flatpickr not mounted yet').to.equal(undefined))
    flatpickr.release()

    cy.get('#form_record_date').should($f => expect($f[0]._flatpickr, 'flatpickr mounted').to.exist).then($f => {
      cy.get('.flatpickr-calendar.open').should('be.visible')
      cy.focused().should($el => expect($el[0], 'the altInput').to.equal($f[0]._flatpickr.altInput))
    })
  })

  // Without an altInput the clicked field stays the one the user types into, and only `open()`
  // makes up for the click flatpickr missed.
  it('opens the calendar of a field with no altInput', () => {
    const flatpickr = holdFlatpickr()
    cy.visit('/bali/form/date/default')
    flatpickr.requested()

    cy.document().then(doc => {
      const input = doc.createElement('input')
      input.id = 'without-alt-input'
      input.dataset.controller = 'datepicker'
      input.dataset.datepickerAltInputValue = 'false'
      doc.body.append(input)
    })
    cy.get('#without-alt-input').should($i => {
      const { Stimulus } = $i[0].ownerDocument.defaultView
      expect(Stimulus.getControllerForElementAndIdentifier($i[0], 'datepicker'), 'connected').to.be.an('object')
    }).focus()
    flatpickr.release()

    cy.get('#without-alt-input').should($i => expect($i[0]._flatpickr?.isOpen, 'calendar open').to.equal(true))
    cy.focused().should('have.id', 'without-alt-input')
  })
})
