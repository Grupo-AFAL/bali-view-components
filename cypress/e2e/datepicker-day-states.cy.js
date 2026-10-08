// `.today` is as specific as `.flatpickr-disabled` and wins on order alone (datepicker.css).
// The class is added by hand so the test does not depend on the day it runs.
const settled = el => expect(el.getAnimations(), 'no transition in flight').to.have.length(0)

describe('Datepicker day states', () => {
  beforeEach(() => {
    cy.visit('/bali/form/date/default')
    cy.get('form input.input:not([type="hidden"])').click()
    cy.get('.flatpickr-calendar.open .flatpickr-day.today').should('be.visible')
  })

  it('a disabled today keeps its ring', () => {
    cy.get('.flatpickr-calendar.open .flatpickr-day.today').then($today => {
      const ring = getComputedStyle($today[0]).borderTopColor
      expect(ring, 'the ring is painted').not.to.equal('rgba(0, 0, 0, 0)')

      $today[0].classList.add('flatpickr-disabled')
      cy.wrap($today).should($day => {
        settled($day[0])
        expect(getComputedStyle($day[0]).borderTopColor).to.equal(ring)
      })
    })
  })
})
