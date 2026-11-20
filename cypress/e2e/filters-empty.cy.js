// #1613 — "is empty" and "is not empty" ask the whole question with the operator, so the row
// draws no value widget and travels a hidden `1` (`q[g][0][genre_null]=1`). The listing's rows say
// what was filtered; the panel's markup, what the row drew.
const container = '[data-condition-target="valueContainer"]'
const movies = () => `${new URL(Cypress.config('baseUrl')).origin}/admin/movies`
const rowNames = ($rows) =>
  $rows.toArray().filter((row) => row.querySelector('td.font-medium')).map((row) => row.querySelector('td.font-medium').textContent.trim())

describe('The empty operators of the advanced filters', () => {
  const without = 'Cypress movie without genre'
  const withGenre = 'Cypress movie with genre'
  // The two rows are told apart from the seeds by name, so the same listing answers either side.
  const onlyOurs = 'q[g][0][name_cont]=Cypress&q[g][0][m]=and'

  const openPanel = () => cy.get('[data-action="click->filters#toggleDropdown"]').first().click()
  const apply = () => cy.get('.filters button').contains('Apply').click()

  before(() => {
    const clean = `Movie.where(name: ["${without}", "${withGenre}"]).destroy_all`
    cy.task('railsRunner', `${clean}; Movie.create!(name: "${without}", genre: nil, studio: Tenant.first); ` +
      `Movie.create!(name: "${withGenre}", genre: "Drama", studio: Tenant.first)`)
  })

  after(() => {
    cy.task('railsRunner', `Movie.where(name: ["${without}", "${withGenre}"]).destroy_all`)
  })

  it('draws no value field for "is empty" and filters the listing by it', () => {
    cy.visit(movies())

    openPanel()
    cy.get('[data-condition-target="attribute"]').first().select('genre')
    cy.get('[data-condition-target="operator"]').first().select('null')

    cy.get(container).first().within(() => {
      cy.get('[data-valueless="true"]').should('have.attr', 'type', 'hidden').and('have.value', '1')
      cy.get('select:visible, input:visible').should('not.exist')
    })
    cy.get('[data-condition-target="hint"].is-shown').should('not.exist')
    apply()

    cy.location('search').should((search) => expect(decodeURIComponent(search)).to.include('q[g][0][genre_null]=1'))
    cy.get('tbody tr').should(($rows) => {
      expect(rowNames($rows)).to.include(without)
      expect(rowNames($rows)).not.to.include(withGenre)
    })
  })

  it('says "is not empty" the other way round', () => {
    cy.visit(`${movies()}?q[g][0][genre_not_null]=1&${onlyOurs}`)

    cy.get('tbody tr').should(($rows) => expect(rowNames($rows)).to.deep.equal([withGenre]))

    // The panel draws the condition it was given: the operator and no value field.
    openPanel()
    cy.get('[data-condition-target="operator"]').first().should('have.value', 'not_null')
    cy.get(container).first().within(() => {
      cy.get('select:visible, input:visible').should('not.exist')
    })
  })

  it('opens a link with an empty condition on that operator, with no value field and no warning', () => {
    cy.visit(`${movies()}?q[g][0][genre_null]=1&q[g][0][m]=and`)

    cy.get('[data-action="click->filters#toggleDropdown"]').first().should('contain', '1')
    openPanel()
    cy.get('[data-condition-target="attribute"]').first().should('have.value', 'genre')
    cy.get('[data-condition-target="operator"]').first().should('have.value', 'null')
    cy.get(container).first().within(() => {
      cy.get('select:visible, input:visible').should('not.exist')
    })
    cy.get('[data-condition-target="hint"].is-shown').should('not.exist')
  })

  it('brings the value field back when the operator goes back to "is", and sends nothing without a value', () => {
    cy.visit(`${movies()}?q[g][0][genre_null]=1&q[g][0][m]=and`)

    openPanel()
    cy.get('[data-condition-target="operator"]').first().select('eq')
    cy.get(`${container} [data-valueless="true"]`).should('not.exist')
    cy.get(`${container} select`).first().should('exist')
    apply()

    cy.location('search').should((search) => expect(decodeURIComponent(search)).not.to.include('genre_'))
  })

  it('does not warn about a missing value after leaving "is empty" and changing the operator again', () => {
    cy.visit(`${movies()}?q[g][0][genre_null]=1&q[g][0][m]=and`)

    openPanel()
    cy.get('[data-condition-target="operator"]').first().select('eq')
    cy.get('[data-condition-target="operator"]').first().select('not_eq')
    cy.get('[data-condition-target="hint"].is-shown').should('not.exist')
  })

  it('draws no condition for a flag that is not true, because it would paint the opposite', () => {
    cy.visit(`${movies()}?q[g][0][genre_null]=0&q[g][0][m]=and`)

    cy.get('[data-action="click->filters#toggleDropdown"]').first().should('not.contain', '1')
    openPanel()
    cy.get('[data-condition-target="attribute"]').first().should('have.value', '')
    cy.get('[data-condition-target="operator"]').first().should('not.have.value', 'null')
  })
})
