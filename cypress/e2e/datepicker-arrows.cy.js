// #1380. With `manual: true` the arrows moved the date without a `change`, so a
// `submit-on-change` form only ever heard the calendar. Counted on the input flatpickr writes,
// which is the one the form submits and the one the documented `data-action` sits on.
describe('Datepicker arrows', () => {
  const field = () => cy.get('input[name="form_record[date]"]')

  beforeEach(() => {
    cy.visit('/bali/form/date/with_controls')
    field().should('have.attr', 'type', 'hidden')
  })

  ;['day', 'month', 'year'].forEach(period => {
    it(`fires one change per click by ${period}`, () => {
      cy.get('[data-controller~="datepicker"]').invoke('attr', 'data-datepicker-period-value', period)

      field().then($input => {
        const changes = []
        const before = $input.val()
        $input[0].addEventListener('change', () => changes.push($input.val()))

        cy.get('[data-action="datepicker#previousDate"]').click()
        field().should($after => {
          expect($after.val()).not.to.equal(before)
          expect(changes).to.deep.equal([$after.val()])
        })

        cy.get('[data-action="datepicker#nextDate"]').click()
        field().should($after => {
          expect($after.val()).to.equal(before)
          expect(changes).to.have.length(2)
        })
      })
    })
  })
})
