// The year input is border-box with 1.5rem of padding for its arrows, and a bare `6ch` left the
// digits 3.3ch of it: «2026» read «202», scrollWidth 61 against a clientWidth of 55.
describe('Datepicker header', () => {
  it('shows the whole year', () => {
    cy.visit('/bali/form/date/default')
    cy.get('form input.input:not([type="hidden"])').click()

    cy.get('.flatpickr-calendar.open .flatpickr-current-month input.cur-year').should(($year) => {
      const year = $year[0]
      expect(year.value, 'a four-digit year').to.match(/^\d{4}$/)
      expect(year.scrollWidth, `«${year.value}» fits its box`).to.be.at.most(year.clientWidth)
    })
  })
})
