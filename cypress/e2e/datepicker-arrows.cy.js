// #1380. With `manual: true` the arrows moved the date without a `change`, so a
// `submit-on-change` form only ever heard the calendar. Counted on the input flatpickr writes,
// which is the one the form submits and the one the documented `data-action` sits on.
describe('Datepicker arrows', () => {
  const field = name => cy.get(`input[name="form_record[${name}]"]`)
  const arrow = (name, action) =>
    field(name).closest('[data-controller~="datepicker"]').find(`[data-action="datepicker#${action}"]`)
  const stepBy = (name, period) =>
    field(name).closest('[data-controller~="datepicker"]').invoke('attr', 'data-datepicker-period-value', period)

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
      stepBy('date', period)

      // The preview seeds today.
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

  // #1409. `setMonth` keeps the day and lets it overflow: January 31 plus a month was March 3.
  ;[
    ['month', 'nextDate', '2026-01-31', '2026-02-28'],
    ['month', 'previousDate', '2026-03-31', '2026-02-28'],
    ['year', 'nextDate', '2028-02-29', '2029-02-28']
  ].forEach(([period, action, from, to]) => {
    it(`lands on the last day of a shorter month: ${from} by ${period} is ${to}`, () => {
      stepBy('date', period)
      field('date').then($input => $input[0]._flatpickr.setDate(from))

      field('date').then($input => {
        const changes = recordChanges($input)

        arrow('date', action).click()
        field('date').should($after => {
          expect($after.val()).to.equal(to)
          expect(changes).to.deep.equal([to])
        })
      })
    })
  })

  // flatpickr drops a disabled date from the selection, so landing on one emptied the field and,
  // announced, submitted `date=`. The preview's weekdays-only field holds a Friday.
  it('skips the disabled dates to the next enabled one, in the direction of the arrow', () => {
    field('end_date').should('have.attr', 'type', 'hidden').and('have.value', '2026-10-16')

    field('end_date').then($input => {
      const changes = recordChanges($input)

      arrow('end_date', 'nextDate').click()
      field('end_date').should($after => {
        expect($after.val()).to.equal('2026-10-19')
        expect(changes).to.deep.equal(['2026-10-19'])
      })

      arrow('end_date', 'previousDate').click()
      field('end_date').should($after => {
        expect($after.val()).to.equal('2026-10-16')
        expect(changes).to.deep.equal(['2026-10-19', '2026-10-16'])
      })
    })
  })

  // The next enabled date here is 2027-10-21, past the year the search covers.
  it('leaves the field alone when no enabled date is within a year', () => {
    field('end_date').should('have.attr', 'type', 'hidden').and('have.value', '2026-10-16')
    field('end_date').then($input => {
      const picker = $input[0]._flatpickr
      picker.set('disable', [...picker.config.disable, { from: '2026-10-19', to: '2027-10-20' }])
    })

    field('end_date').then($input => {
      const changes = recordChanges($input)

      arrow('end_date', 'nextDate').click()
      field('end_date').should($after => {
        expect($after.val()).to.equal('2026-10-16')
        expect(changes).to.deep.equal([])
      })
    })
  })
})
