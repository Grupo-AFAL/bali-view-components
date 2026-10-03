// #1282 — what a between condition shows has to be what it filters by, so these read the rows the
// server sends back on the dummy's listing, not the markup of the row.
describe('A between condition', () => {
  const container = '[data-condition-target="valueContainer"]'
  const movies = () => `${new URL(Cypress.config('baseUrl')).origin}/admin/movies`

  // YYYY-MM-DD, `days` away from another one. In UTC, so a DST change on the machine running
  // the browser cannot move the day.
  const shift = (isoDate, days) => {
    const [year, month, day] = isoDate.split('-').map(Number)
    return new Date(Date.UTC(year, month - 1, day + days)).toISOString().slice(0, 10)
  }

  // The day each row was created on, in the app's time zone: `<time datetime>` carries its
  // offset, and Ransack casts the range in that same zone. An empty listing still has a row, the
  // empty state, which has neither.
  const movieRows = ($rows) => $rows.toArray().filter((row) => row.querySelector('time[datetime]'))
  const rowDays = ($rows) => movieRows($rows).map((row) => row.querySelector('time[datetime]').getAttribute('datetime').slice(0, 10))
  const rowNames = ($rows) => movieRows($rows).map((row) => row.querySelector('td.font-medium').textContent.trim())

  // flatpickr asks `instanceof Array`, which an array built in the spec's window fails: it then
  // picks nothing at all.
  const pickRange = (from, to) =>
    cy.get(`${container} [data-controller="datepicker"]`)
      .should(($input) => expect($input[0]._flatpickr, 'flatpickr mounted').to.exist)
      .then(($input) => {
        const page = $input[0].ownerDocument.defaultView
        $input[0]._flatpickr.setDate(page.Array.of(from, to), true)
      })

  const expectRowsWithin = (from, to, name) =>
    cy.get('tbody tr').should(($rows) => {
      rowDays($rows).forEach((created) =>
        expect(created >= from && created <= to, `a row created on ${created}, within ${from}..${to}`).to.equal(true))
      expect(rowNames($rows)).to.include(name)
    })

  // With "between" chosen, choosing another date field kept the operator but painted a single
  // picker named `<field>_between`, a predicate Ransack 4.4 does not have and drops without a
  // word: the listing came back unfiltered under a row that still said "between".
  it('still filters the listing by both ends of the range when carried to another date field', () => {
    cy.visit(movies())

    // The seeds space the movies 37 days apart, so a three-day window around one of them holds
    // that one alone.
    cy.get('tbody tr').eq(1).then(($anchor) => {
      const [name] = rowNames($anchor)
      const [day] = rowDays($anchor)
      const from = shift(day, -1)
      const to = shift(day, 1)

      cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
      cy.get('[data-condition-target="attribute"]').select('production_starts_on')
      cy.get('[data-condition-target="operator"]').select('between')
      cy.get('[data-condition-target="attribute"]').select('created_at')
      pickRange(from, to)
      cy.get('.filters button').contains('Apply').click()

      expectRowsWithin(from, to, name)
      cy.location('search').should((search) => {
        const keys = Array.from(new URLSearchParams(search).keys())
        expect(keys).to.include.members(['q[g][0][created_at_gteq]', 'q[g][0][created_at_lteq]'])
      })
    })
  })

  // The picker sends bare dates and Ransack cast the top one, over a datetime column, to that
  // day's midnight: a row created later that day was left out.
  it('keeps the rows of its last day', () => {
    cy.visit(movies())

    cy.get('tbody tr').eq(1).then(($anchor) => {
      const [name] = rowNames($anchor)
      const [day] = rowDays($anchor)
      const from = shift(day, -2)

      cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
      cy.get('[data-condition-target="attribute"]').select('created_at')
      cy.get('[data-condition-target="operator"]').select('between')
      pickRange(from, day)
      cy.get('.filters button').contains('Apply').click()

      // The bare date Bali::FilterForm::WholeDayCasting::BARE_DATE reads as a whole day.
      cy.location('search').should((search) =>
        expect(new URLSearchParams(search).get('q[g][0][created_at_lteq]')).to.equal(day))
      expectRowsWithin(from, day, name)
    })
  })

  it('shows a datetime range as the whole days it sends', () => {
    cy.visit('/bali/filters/all_field_types?popover=false')

    cy.get('[data-condition-target="attribute"]').first().select('last_login')
    cy.get('[data-condition-target="operator"]').first().select('between')
    pickRange('2026-08-25', '2026-08-27')

    cy.get(`${container} [data-condition-target="rangeInput"]`).should(($input) => {
      expect($input[0]._flatpickr.altInput.value).to.equal('Aug 25, 2026 to Aug 27, 2026')
    })
    cy.get(`${container} [data-condition-target="rangeStart"]`).should('have.value', '2026-08-25')
    cy.get(`${container} [data-condition-target="rangeEnd"]`).should('have.value', '2026-08-27')
  })
})
