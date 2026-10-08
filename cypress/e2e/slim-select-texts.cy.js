// #1232 — the strings SlimSelect paints come from Bali's i18n through the controller's values.
// Each test reads what SlimSelect drew, so a value Ruby emits and the controller does not
// hand over fails here even though the attribute is in the markup.
describe('SlimSelect texts', () => {
  const searchFor = (term) => {
    cy.get('.ss-main').first().click()
    cy.get('.ss-content.ss-open .ss-search input').type(term)
  }
  const listMessage = () => cy.get('.ss-content.ss-open .ss-list .ss-search')

  // Past `maxValuesShown` (20) SlimSelect replaces the chips with one `.ss-max` count.
  it('collapses many values into a count in the page language', () => {
    cy.visit('/bali/form/slim_select/many_selected?locale=es')

    cy.get('.ss-main .ss-values .ss-max').should('have.text', '27 seleccionados')
    cy.get('.ss-main .ss-values .ss-value').should('have.length', 0)
  })

  it('offers to add the typed value in the page language', () => {
    cy.visit('/bali/form/slim_select/addable?locale=es')
    searchFor('Mango')

    listMessage().should('have.text', 'Presiona "Enter" para agregar Mango')
  })

  // From 3.5 SlimSelect reads out the clear button and each tag's remove button, and from 3.6
  // the count of results in its live region (.ss-status, kept off screen by slim_select.css).
  it('reads out its buttons and the count of results in the page language', () => {
    cy.visit('/bali/form/slim_select/multiple?locale=es')
    cy.get('.ss-main').first().click()
    cy.get('.ss-content.ss-open .ss-option').contains('Option 1').click()
    searchFor('Option')

    cy.get('.ss-main .ss-deselect').should('have.attr', 'aria-label', 'Borrar selección')
    cy.get('.ss-main .ss-value-delete').should('have.attr', 'aria-label', 'Quitar Option 1')
    cy.get('.ss-content.ss-open .ss-status').should('have.text', '5 resultados disponibles')
  })

  describe('in the Filters panel', () => {
    // The dummy app lives above the Lookbook preview path `baseUrl` points at.
    const appOrigin = new URL(Cypress.config('baseUrl')).origin
    const openPanel = () => cy.get('[data-filters-target="dropdown"] > button').click()
    const searchValueFor = (term) => {
      cy.get('[data-condition-target="valueContainer"] .ss-main').click()
      cy.get('.ss-content.ss-open .ss-search input').type(term)
    }

    // condition_controller.js#buildSelectInput writes this select when an attribute is picked.
    it('says there are no results in the page language on a condition built in the browser', () => {
      cy.visit(`${appOrigin}/admin/movies?locale=es`)
      openPanel()
      cy.get('[data-condition-target="attribute"]').select('genre')
      searchValueFor('zzz')

      listMessage().should('have.text', 'Sin resultados')
    })

    it('reads out the clear button and the count of results in the page language on a condition built in the browser', () => {
      cy.visit(`${appOrigin}/admin/movies?locale=es`)
      openPanel()
      cy.get('[data-condition-target="attribute"]').select('genre')
      searchValueFor('a')

      cy.get('[data-condition-target="valueContainer"] .ss-deselect').should('have.attr', 'aria-label', 'Borrar selección')
      cy.get('.ss-content.ss-open .ss-status').invoke('text').should('match', /^\d+ resultados disponibles$/)
      // A single select draws no tags, so the remove text is only ever on the markup here.
      cy.get('[data-condition-target="valueContainer"] [data-controller="slim-select"]')
        .should('have.attr', 'data-slim-select-remove-text-value', 'Quitar')
    })

    // filters/condition/component.html.erb writes this one for a filter already applied.
    it('says there are no results in the page language on a condition painted by the server', () => {
      cy.visit(`${appOrigin}/admin/movies`, {
        qs: { locale: 'es', 'q[g][0][m]': 'and', 'q[g][0][genre_eq]': 'Drama' }
      })
      openPanel()
      searchValueFor('zzz')

      listMessage().should('have.text', 'Sin resultados')
    })

    it('reads out the clear button and the count of results in the page language on a condition painted by the server', () => {
      cy.visit(`${appOrigin}/admin/movies`, {
        qs: { locale: 'es', 'q[g][0][m]': 'and', 'q[g][0][genre_eq]': 'Drama' }
      })
      openPanel()
      searchValueFor('a')

      cy.get('[data-condition-target="valueContainer"] .ss-deselect').should('have.attr', 'aria-label', 'Borrar selección')
      cy.get('.ss-content.ss-open .ss-status').invoke('text').should('match', /^\d+ resultados disponibles$/)
    })
  })
})
