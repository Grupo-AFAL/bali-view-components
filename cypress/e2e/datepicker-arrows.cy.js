// #1380. With `manual: true` the arrows moved the date without a `change`, so a
// `submit-on-change` form only ever heard the calendar. Counted on the input flatpickr writes,
// which is the one the form submits and the one the documented `data-action` sits on.
describe('Datepicker arrows', () => {
  const field = name => cy.get(`input[name="form_record[${name}]"]`)
  const arrow = (name, action) =>
    field(name).closest('[data-controller~="datepicker"]').find(`[data-action="datepicker#${action}"]`)

  // Every change the input announces, with the value it carried at the time.
  const recordChanges = $input => {
    const changes = []
    $input[0].addEventListener('change', () => changes.push($input.val()))
    return changes
  }

  beforeEach(() => {
    cy.visit('/bali/form/date/with_controls')
    field('date').should('have.attr', 'type', 'hidden')
  })

  ;[
    ['day', '2026-10-14'],
    ['month', '2026-09-15'],
    ['year', '2025-10-15']
  ].forEach(([period, previous]) => {
    it(`fires one change per click by ${period}`, () => {
      field('date').closest('[data-controller~="datepicker"]')
        .invoke('attr', 'data-datepicker-period-value', period)

      // The preview seeds today, and a month step from the 29th on overflows into the next one.
      field('date').then($input => $input[0]._flatpickr.setDate('2026-10-15'))

      field('date').then($input => {
        const changes = recordChanges($input)

        arrow('date', 'previousDate').click()
        field('date').should($after => {
          expect($after.val()).to.equal(previous)
          expect(changes).to.deep.equal([previous])
        })

        arrow('date', 'nextDate').click()
        field('date').should($after => {
          expect($after.val()).to.equal('2026-10-15')
          expect(changes).to.deep.equal([previous, '2026-10-15'])
        })
      })
    })
  })

  // flatpickr drops a disabled date from the selection, so stepping onto one emptied the field —
  // and, announced, submitted `date=`. The preview's weekdays-only field holds a Friday.
  it('leaves the field alone when the step lands on a disabled date', () => {
    field('end_date').should('have.attr', 'type', 'hidden').and('have.value', '2026-10-16')

    field('end_date').then($input => {
      const changes = recordChanges($input)

      arrow('end_date', 'nextDate').click()
      field('end_date').should($after => {
        expect($after.val()).to.equal('2026-10-16')
        expect(changes).to.deep.equal([])
      })

      arrow('end_date', 'previousDate').click()
      field('end_date').should($after => {
        expect($after.val()).to.equal('2026-10-15')
        expect(changes).to.deep.equal(['2026-10-15'])
      })
    })
  })
})
