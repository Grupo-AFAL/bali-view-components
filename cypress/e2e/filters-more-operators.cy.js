// v3.29.0 — "between" over numbers, "does not start / end with" over text and "not on" over
// dates. The listing's rows say what was filtered; the panel's markup, what the row drew.
const container = '[data-condition-target="valueContainer"]'
const movies = () => `${new URL(Cypress.config('baseUrl')).origin}/admin/movies`
const rowNames = ($rows) =>
  $rows.toArray().filter((row) => row.querySelector('td.font-medium')).map((row) => row.querySelector('td.font-medium').textContent.trim())

describe('The operators the advanced panel gained', () => {
  const openPanel = () => cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
  const apply = () => cy.get('.filters button').contains('Apply').click()
  const attribute = () => cy.get('[data-condition-target="attribute"]').first()
  const operator = () => cy.get('[data-condition-target="operator"]').first()

  describe('between, over a number', () => {
    // The seeds' budgets: The Dark Knight 185M, Inception 160M, Interstellar 165M, Top Gun 170M,
    // Dune within; Frozen (150M) and The Avengers (220M) outside.
    it('draws two number fields and filters by both ends', () => {
      cy.visit(movies())
      openPanel()
      attribute().select('budget')
      operator().select('between')

      cy.get(`${container} input[type="number"]`).should('have.length', 2)
      cy.get('[data-condition-target="rangeStart"]').type('160000000')
      cy.get('[data-condition-target="rangeEnd"]').type('185000000')
      apply()

      cy.location('search').should((search) => {
        expect(decodeURIComponent(search)).to.include('q[g][0][budget_gteq]=160000000')
        expect(decodeURIComponent(search)).to.include('q[g][0][budget_lteq]=185000000')
      })
      cy.get('tbody tr').should(($rows) => {
        const names = rowNames($rows)
        expect(names).to.include('Inception')
        expect(names).not.to.include('Frozen')
        expect(names).not.to.include('The Avengers')
      })
    })

    it('is painted again as one condition from a link written with its two bounds', () => {
      cy.visit(`${movies()}?q[g][0][budget_gteq]=160000000&q[g][0][budget_lteq]=185000000&q[g][0][m]=and`)

      cy.get('[data-action="click->filters#toggleDropdown"]').first().should('contain', '1')
      openPanel()
      operator().should('have.value', 'between')
      cy.get('[data-condition-target="rangeStart"]').first().should('have.value', '160000000')
      cy.get('[data-condition-target="rangeEnd"]').first().should('have.value', '185000000')
    })

    it('goes back to one field with "is", and asks for both ends again after', () => {
      cy.visit(`${movies()}?q[g][0][budget_gteq]=160000000&q[g][0][budget_lteq]=185000000&q[g][0][m]=and`)

      openPanel()
      operator().select('eq')
      cy.get(`${container} input[type="number"]`).should('have.length', 1)
      cy.get('[data-condition-target="rangeStart"]').should('not.exist')
      operator().select('between')
      cy.get(`${container} input[type="number"]`).should('have.length', 2)
    })

    it('does not send half a range', () => {
      cy.visit(movies())
      openPanel()
      attribute().select('budget')
      operator().select('between')
      cy.get('[data-condition-target="rangeStart"]').type('160000000')
      apply()

      cy.location('search').should((search) => expect(decodeURIComponent(search)).not.to.include('budget_'))
    })
  })

  describe('does not start with / does not end with, over text', () => {
    it('leaves out the rows that start with the text', () => {
      cy.visit(movies())
      openPanel()
      attribute().select('name')
      operator().find('option').then(($options) => {
        const labels = [...$options].map((option) => option.textContent.trim())
        expect(labels).to.include.members(['does not start with', 'does not end with'])
      })
      operator().select('does not start with')
      cy.get(`${container} input`).first().type('The ')
      apply()

      cy.get('tbody tr').should(($rows) => {
        const names = rowNames($rows)
        expect(names).to.include('Inception')
        names.forEach((name) => expect(name.startsWith('The '), name).to.equal(false))
      })
    })

    it('leaves out the rows that end with the text', () => {
      cy.visit(movies())
      openPanel()
      attribute().select('name')
      operator().select('does not end with')
      cy.get(`${container} input`).first().type('Park')
      apply()

      cy.get('tbody tr').should(($rows) => {
        const names = rowNames($rows)
        expect(names).to.include('Inception')
        expect(names).not.to.include('Jurassic Park')
      })
    })
  })

  describe('not on, over a date', () => {
    // The seeds are created 37 days apart: the day of one row holds that row alone, and a `!=`
    // midnight would leave it in, since no seed is created at exactly midnight.
    it('leaves out every row of that day, though no row is created at midnight', () => {
      cy.visit(movies())
      cy.get('tbody tr').eq(1).then(($anchor) => {
        const [name] = rowNames($anchor)
        const day = $anchor[0].querySelector('time[datetime]').getAttribute('datetime').slice(0, 10)

        cy.visit(`${movies()}?q[g][0][created_at_not_eq]=${day}&q[g][0][m]=and`)
        cy.get('tbody tr').should(($rows) => {
          expect(rowNames($rows), `a row created on ${day}`).not.to.include(name)
          expect(rowNames($rows).length).to.be.greaterThan(1)
        })
        openPanel()
        attribute().should('have.value', 'created_at')
        operator().should('have.value', 'not_eq')
      })
    })
  })
})
