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

  // #1389 — a select written by hand carries no `data-slim-select-*-value` texts, so the
  // controller falls back to its own table in the page's `lang`. The preview puts it beside a
  // slim_select_field, whose texts come from config/locales/bali_view.*.yml, so a string in
  // that table drifting from the YAML fails here as well as in slim_select_fields_test.rb.
  describe('written by hand', () => {
    const TEXT_SETTINGS = ['placeholderText', 'searchPlaceholder', 'searchText', 'searchingText',
      'maxValuesMessage', 'addableText', 'deselectText', 'removeText', 'resultsText']
    const textSettings = element => {
      const controller = element.ownerDocument.defaultView.Stimulus
        .getControllerForElementAndIdentifier(element, 'slim-select')
      return Object.fromEntries(TEXT_SETTINGS.map(name => [name, controller.select.settings[name]]))
    }
    const handWritten = () => cy.get('[data-controller="slim-select"]').eq(1).find('.ss-main')

    ;['en', 'es'].forEach(lang => {
      it(`hands SlimSelect what slim_select_field hands it, in ${lang}`, () => {
        cy.visit(`/bali/form/slim_select/hand_written?lang=${lang}`)

        cy.get('[data-controller="slim-select"] .ss-main').should('have.length', 2)
        cy.get('[data-controller="slim-select"]').then($selects => {
          const [builder, byHand] = $selects.toArray().map(textSettings)
          expect(byHand).to.deep.equal(builder)
        })
      })
    })

    it('paints and reads out the page language', () => {
      cy.visit('/bali/form/slim_select/hand_written?lang=es')

      handWritten().find('.ss-placeholder').should('have.text', 'Selecciona una opción')
      handWritten().find('.ss-deselect').should('have.attr', 'aria-label', 'Borrar selección')
      handWritten().click()
      cy.get('.ss-content.ss-open .ss-search input').should('have.attr', 'placeholder', 'Buscar')
        .type('Option')
      cy.get('.ss-content.ss-open .ss-status').should('have.text', '5 resultados disponibles')
      cy.get('.ss-content.ss-open .ss-search input').clear().type('zzz')
      listMessage().should('have.text', 'Sin resultados')
    })

    it('keeps a text written on the element over the page language', () => {
      cy.visit('/bali/form/slim_select/hand_written?lang=es')
      cy.get('[lang="es"]').then($page => $page[0].insertAdjacentHTML('beforeend', `
        <div id="explicit" data-controller="slim-select" data-slim-select-no-results-text-value="Nothing here">
          <select data-slim-select-target="select"><option>Option 1</option></select>
        </div>`))

      cy.get('#explicit .ss-main').click()
      cy.get('.ss-content.ss-open .ss-search input').should('have.attr', 'placeholder', 'Buscar')
        .type('zzz')
      listMessage().should('have.text', 'Nothing here')
    })
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
